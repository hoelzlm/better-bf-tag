import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod';
import { z } from 'zod';
import { and, asc, eq, ne } from 'drizzle-orm';
import { person, fireDepartment } from '../db/schema.js';
import { requireAuth, requirePermission } from '../access/authenticate.js';
import { errorResponseSchema } from '../access/schemas.js';
import { hashPassword } from '../access/passwords.js';
import { deactivatePersonSessions } from '../access/sessions.js';
import { personJsonSchema, toPersonJson, type PersonRow } from './person-schemas.js';
import { ApiError } from '../errors.js';
import type { Tx } from '../realtime/realtime.js';
import type { PersonType, Permission } from '../access/types.js';

const personTypeSchema = z.enum(['youth', 'supervisor']);
const permissionSchema = z.enum(['crew', 'preparation', 'dispatch', 'admin']);

const createPersonBodySchema = z.object({
  display_name: z.string().trim().min(1).max(60),
  person_type: personTypeSchema,
  permission: permissionSchema,
});

const updatePersonBodySchema = z.object({
  display_name: z.string().trim().min(1).max(60).optional(),
  person_type: personTypeSchema.optional(),
  permission: permissionSchema.optional(),
  active: z.boolean().optional(),
});

const webAccessBodySchema = z.object({
  username: z
    .string()
    .trim()
    .min(3)
    .max(40)
    .regex(/^[a-z0-9._-]+$/, 'username darf nur Kleinbuchstaben, Ziffern, "." "_" "-" enthalten'),
  password: z.string().min(8),
});

const personListResponseSchema = z.array(personJsonSchema);

function personNotFound(): ApiError {
  return new ApiError(404, 'not_found', 'Person nicht gefunden.');
}

/** 400 admin_requires_supervisor: Administrator nur bei Personentyp Betreuer (ADR 0010). */
function assertAdminRequiresSupervisor(personType: PersonType, permission: Permission): void {
  if (permission === 'admin' && personType !== 'supervisor') {
    throw new ApiError(
      400,
      'admin_requires_supervisor',
      'Berechtigung Administrator erfordert Personentyp Betreuer.'
    );
  }
}

async function loadPerson(tx: Tx, id: string): Promise<PersonRow | undefined> {
  const [row] = await tx.select().from(person).where(eq(person.id, id)).limit(1);
  return row;
}

/** 409 last_admin: the last active admin may not be demoted or deactivated. */
async function assertNotLastAdmin(tx: Tx, existing: PersonRow): Promise<void> {
  const [otherAdmin] = await tx
    .select({ id: person.id })
    .from(person)
    .where(and(eq(person.permission, 'admin'), eq(person.active, true), ne(person.id, existing.id)))
    .limit(1);
  if (!otherAdmin) {
    throw new ApiError(
      409,
      'last_admin',
      'Die letzte aktive Person mit Berechtigung Administrator kann nicht geändert werden.'
    );
  }
}

export const personRoutes: FastifyPluginAsyncZod = async fastify => {
  fastify.get(
    '/persons',
    {
      preHandler: [requireAuth, requirePermission('admin')],
      schema: {
        operationId: 'listPersons',
        tags: ['persons'],
        response: {
          200: personListResponseSchema,
        },
      },
    },
    async () => {
      const rows = await fastify.db.select().from(person).orderBy(asc(person.displayName));
      return rows.map(toPersonJson);
    }
  );

  fastify.get(
    '/persons/:id',
    {
      preHandler: [requireAuth, requirePermission('admin')],
      schema: {
        operationId: 'getPerson',
        tags: ['persons'],
        params: z.object({ id: z.string().uuid() }),
        response: {
          200: personJsonSchema,
          404: errorResponseSchema,
        },
      },
    },
    async request => {
      const [row] = await fastify.db
        .select()
        .from(person)
        .where(eq(person.id, request.params.id))
        .limit(1);
      if (!row) {
        throw personNotFound();
      }
      return toPersonJson(row);
    }
  );

  fastify.post(
    '/persons',
    {
      preHandler: [requireAuth, requirePermission('admin')],
      schema: {
        operationId: 'createPerson',
        tags: ['persons'],
        body: createPersonBodySchema,
        response: {
          201: personJsonSchema,
          400: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      assertAdminRequiresSupervisor(request.body.person_type, request.body.permission);

      const [own] = await fastify.db
        .select({ id: fireDepartment.id })
        .from(fireDepartment)
        .where(eq(fireDepartment.isOwn, true))
        .limit(1);
      if (!own) {
        throw new Error('createPerson: own fire department is missing');
      }

      const [row] = await fastify.db
        .insert(person)
        .values({
          fireDepartmentId: own.id,
          displayName: request.body.display_name,
          personType: request.body.person_type,
          permission: request.body.permission,
          username: null,
          passwordHash: null,
          active: true,
        })
        .returning();
      if (!row) {
        throw new Error('createPerson: insert returned no row');
      }

      return reply.status(201).send(toPersonJson(row));
    }
  );

  fastify.patch(
    '/persons/:id',
    {
      preHandler: [requireAuth, requirePermission('admin')],
      schema: {
        operationId: 'updatePerson',
        tags: ['persons'],
        params: z.object({ id: z.string().uuid() }),
        body: updatePersonBodySchema,
        response: {
          200: personJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.db.transaction(async tx => {
        const existing = await loadPerson(tx, request.params.id);
        if (!existing) {
          throw personNotFound();
        }

        const nextPersonType = request.body.person_type ?? existing.personType;
        const nextPermission = request.body.permission ?? existing.permission;
        const nextActive = request.body.active ?? existing.active;

        assertAdminRequiresSupervisor(nextPersonType, nextPermission);

        const wasActiveAdmin = existing.permission === 'admin' && existing.active;
        const losesAdminOrActive = nextPermission !== 'admin' || !nextActive;
        if (wasActiveAdmin && losesAdminOrActive) {
          await assertNotLastAdmin(tx, existing);
        }

        const patch: Partial<PersonRow> = {};
        if (request.body.display_name !== undefined) {
          patch.displayName = request.body.display_name;
        }
        if (request.body.person_type !== undefined) {
          patch.personType = request.body.person_type;
        }
        if (request.body.permission !== undefined) {
          patch.permission = request.body.permission;
        }
        if (request.body.active !== undefined) {
          patch.active = request.body.active;
        }

        const becomesCrew = nextPermission === 'crew';
        if (becomesCrew) {
          patch.username = null;
          patch.passwordHash = null;
        }

        const [row] = await tx
          .update(person)
          .set(patch)
          .where(eq(person.id, request.params.id))
          .returning();
        if (!row) {
          throw personNotFound();
        }

        if (becomesCrew || nextActive === false) {
          await deactivatePersonSessions(tx, row.id, fastify.clock.now());
        }

        return toPersonJson(row);
      });
    }
  );

  fastify.put(
    '/persons/:id/web-access',
    {
      preHandler: [requireAuth, requirePermission('admin')],
      schema: {
        operationId: 'setWebAccess',
        tags: ['persons'],
        params: z.object({ id: z.string().uuid() }),
        body: webAccessBodySchema,
        response: {
          200: personJsonSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async request => {
      return fastify.db.transaction(async tx => {
        const existing = await loadPerson(tx, request.params.id);
        if (!existing) {
          throw personNotFound();
        }
        if (existing.permission === 'crew') {
          throw new ApiError(
            400,
            'web_access_not_allowed',
            'Mannschaft darf keinen Web-Zugang erhalten.'
          );
        }

        const [taken] = await tx
          .select({ id: person.id })
          .from(person)
          .where(and(eq(person.username, request.body.username), ne(person.id, existing.id)))
          .limit(1);
        if (taken) {
          throw new ApiError(409, 'username_taken', 'Benutzername ist bereits vergeben.');
        }

        const passwordHash = await hashPassword(request.body.password);

        const [row] = await tx
          .update(person)
          .set({ username: request.body.username, passwordHash })
          .where(eq(person.id, existing.id))
          .returning();
        if (!row) {
          throw personNotFound();
        }

        // Setting (or re-setting) credentials always rotates the password,
        // so any existing web session must be revoked (ADR 0010).
        await deactivatePersonSessions(tx, row.id, fastify.clock.now());

        return toPersonJson(row);
      });
    }
  );

  fastify.delete(
    '/persons/:id/web-access',
    {
      preHandler: [requireAuth, requirePermission('admin')],
      schema: {
        operationId: 'removeWebAccess',
        tags: ['persons'],
        params: z.object({ id: z.string().uuid() }),
      },
    },
    async (request, reply) => {
      await fastify.db.transaction(async tx => {
        const existing = await loadPerson(tx, request.params.id);
        if (!existing) {
          throw personNotFound();
        }

        await tx
          .update(person)
          .set({ username: null, passwordHash: null })
          .where(eq(person.id, existing.id));

        await deactivatePersonSessions(tx, existing.id, fastify.clock.now());
      });

      return reply.status(204).send();
    }
  );

  // No DELETE route for persons: deactivation only (ADR 0010).
};
