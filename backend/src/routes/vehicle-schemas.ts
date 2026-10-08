import { z } from 'zod';

/**
 * The public shape of a Fahrzeug (vehicle), shared between the vehicle
 * routes and the snapshot route so the two don't drift.
 */
export const vehicleSchema = z.object({
  id: z.string(),
  call_sign: z.string(),
  short_name: z.string(),
  type: z.string(),
  status: z.number().int(),
  status_changed_at: z.string().nullable(),
  sort_order: z.number().int(),
  active: z.boolean(),
});

export type VehicleJson = z.infer<typeof vehicleSchema>;

export interface VehicleRow {
  id: string;
  callSign: string;
  shortName: string;
  type: string;
  status: number;
  statusChangedAt: Date | null;
  sortOrder: number;
  active: boolean;
}

export function toVehicleJson(row: VehicleRow): VehicleJson {
  return {
    id: row.id,
    call_sign: row.callSign,
    short_name: row.shortName,
    type: row.type,
    status: row.status,
    status_changed_at: row.statusChangedAt ? row.statusChangedAt.toISOString() : null,
    sort_order: row.sortOrder,
    active: row.active,
  };
}
