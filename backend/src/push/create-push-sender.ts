import { readFileSync } from 'node:fs';
import type { Config } from '../config.js';
import { FcmPushSender, type FcmServiceAccount } from './fcm-sender.js';
import { ApnsPushSender } from './apns-sender.js';
import { PlatformPushSender } from './platform-sender.js';
import type { PushSender } from './push-sender.js';

export interface SenderLogger {
  warn(message: string): void;
}

/**
 * Builds the production PushSender from config (ADR 0018): reads the FCM
 * service-account JSON and the APNs .p8 key from disk, if configured. A
 * platform without complete configuration is left out of PlatformPushSender
 * (⇒ rejected at send time) and logs a warning once at startup.
 */
export function createPushSender(config: Config, log: SenderLogger): PushSender {
  let android: PushSender | undefined;
  if (config.FCM_SERVICE_ACCOUNT_FILE) {
    const serviceAccount = JSON.parse(
      readFileSync(config.FCM_SERVICE_ACCOUNT_FILE, 'utf-8')
    ) as FcmServiceAccount;
    android = new FcmPushSender({ serviceAccount });
  } else {
    log.warn(
      'FCM nicht konfiguriert (FCM_SERVICE_ACCOUNT_FILE fehlt) – Android-Push wird abgelehnt.'
    );
  }

  let ios: PushSender | undefined;
  const apnsConfigured = Boolean(
    config.APNS_KEY_FILE && config.APNS_KEY_ID && config.APNS_TEAM_ID && config.APNS_BUNDLE_ID
  );
  if (apnsConfigured) {
    const key = readFileSync(config.APNS_KEY_FILE as string, 'utf-8');
    ios = new ApnsPushSender({
      key,
      keyId: config.APNS_KEY_ID as string,
      teamId: config.APNS_TEAM_ID as string,
      bundleId: config.APNS_BUNDLE_ID as string,
      production: config.APNS_PRODUCTION,
    });
  } else {
    log.warn(
      'APNs nicht konfiguriert (APNS_KEY_FILE/APNS_KEY_ID/APNS_TEAM_ID/APNS_BUNDLE_ID fehlt) – iOS-Push wird abgelehnt.'
    );
  }

  return new PlatformPushSender({ android, ios });
}
