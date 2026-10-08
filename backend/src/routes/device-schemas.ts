import { z } from 'zod';

/**
 * The public shape of a Gerät (device), shared by the devices/persons
 * routes so they don't drift.
 */
export const deviceJsonSchema = z.object({
  id: z.string(),
  platform: z.enum(['android', 'ios']),
  device_name: z.string().nullable(),
  app_version: z.string(),
  created_at: z.string(),
  last_seen_at: z.string(),
  revoked_at: z.string().nullable(),
});

export type DeviceJson = z.infer<typeof deviceJsonSchema>;

export interface DeviceRow {
  id: string;
  platform: 'android' | 'ios';
  deviceName: string | null;
  appVersion: string;
  createdAt: Date;
  lastSeenAt: Date;
  revokedAt: Date | null;
}

export function toDeviceJson(row: DeviceRow): DeviceJson {
  return {
    id: row.id,
    platform: row.platform,
    device_name: row.deviceName,
    app_version: row.appVersion,
    created_at: row.createdAt.toISOString(),
    last_seen_at: row.lastSeenAt.toISOString(),
    revoked_at: row.revokedAt ? row.revokedAt.toISOString() : null,
  };
}
