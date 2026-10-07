# ADR 0006 – Quittierung statt „komme / komme nicht“

- **Status:** Angenommen
- **Datum:** 2026-10-07

Feuerwehr-Alarm-Apps kennen fast immer eine Rückmeldung „komme / komme nicht“. Diese Logik stammt
aus der Freiwilligen Feuerwehr: Die Einsatzkräfte sind zu Hause und entscheiden, ob sie kommen.
Beim BF-Tag spielen wir Berufsfeuerwehr. Die Besatzung hat Dienst auf der Wache und rückt aus,
eine Absage ist nicht vorgesehen. Deshalb gibt es nur eine **Quittierung** pro Person
(„Alarm erhalten“). Das Ausrücken bestätigt der **Fahrzeugstatus** 3. Die Quittierung zeigt der
Leitstelle vor allem, wessen Handy nicht klingelt (Zustände: quittiert / ausstehend / kein Gerät).
Eine Zu- oder Absage bitte nicht „nachrüsten“: Sie würde die BF-Simulation verfälschen.
