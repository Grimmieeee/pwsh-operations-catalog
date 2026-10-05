# Publishing Checklist

Run this before making a script, document, or workflow publicly available.

## Source review

- [ ] The file is intentionally approved for public release.
- [ ] The current version is the intended canonical version.
- [ ] The filename is clear and stable.
- [ ] Comments do not expose internal context.
- [ ] Example values are generic.

## Secret scan

Confirm the file contains no:

- passwords;
- API keys;
- access or refresh tokens;
- client secrets;
- private keys;
- certificate private material;
- connection strings;
- embedded credentials.

## Proprietary / environment scan

Remove or replace:

- client/company names;
- tenant IDs;
- internal domains;
- user UPNs;
- server and jumpbox names;
- private filesystem paths;
- internal ticket formats when not needed;
- app-registration IDs;
- certificate subjects/thumbprints;
- protected-group names;
- private allowlists / exclusion lists;
- internal repository names when they add no public value.

## Operational review

- [ ] Risk flag matches behavior.
- [ ] Required permissions are documented.
- [ ] Destructive actions are obvious.
- [ ] Confirmation behavior is appropriate.
- [ ] Error paths are reviewable.
- [ ] Data gaps are not presented as clean.
- [ ] Export behavior is safe.

## Catalog review

- [ ] Display name matches the actual task.
- [ ] Scope is correct.
- [ ] Purpose/category is correct.
- [ ] Filename is correct.
- [ ] Card checklist reflects real behavior.
- [ ] Connect command is accurate.
- [ ] Source loads from an approved same-origin path.
- [ ] COPY and SAVE actions work.
