# Stash iOS

Stash is an iOS application fulfilling the client-side responsibilities in Steve Gibson’s SQRL (Secure, Quick, Reliable Login) authentication model.

## A little bit about SQRL
SQRL is an authentication model which can be substituted for (or used alongside) the traditional username and password authentication paradigm. In the traditional model, a user will provide their username and password to a service where it is then validated against a copy stored by the service. SQRL removes the requirement for a service to hold a copy of a user's secret (their password); responsibility for keeping that secret safe is now solely the responsibility of the user. The service, in the SQRL model, only needs to store a 256-bit unique identifier - which does not compromise the user's security if the service’s security is breached. A thorough and more articulate description, including a cryptographic architecture and protocol specification can be found at https://www.grc.com/sqrl/sqrl.htm.
