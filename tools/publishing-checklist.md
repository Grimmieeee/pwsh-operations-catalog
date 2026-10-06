# Publishing Checklist

Run this before making a script, document, or workflow publicly available.

## Source review

- [ ] The file is intentionally approved for public release.
- [ ] The current version is the intended canonical version.
- [ ] The filename is clear and stable.
- [ ] Comments do not expose internal context.
- [ ] Example values are generic.
- [ ] Authenticode signature blocks from internal/private signing identities are removed from the public copy unless intentionally published.
- [ ] Publication did not modify the user's working/original script.
- [ ] The public copy is the exact version that was reviewed and approved.
- [ ] Any executable change made during sanitization was treated as a new revision and reviewed again.

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
- [ ] The script does not rely on an unstated repository/current-directory assumption.
- [ ] File Explorer > Run with PowerShell works when that is the intended launch model.
- [ ] Missing modules, permissions, or prerequisites fail with an actionable message.

## Catalog review

- [ ] Display name matches the actual task.
- [ ] Scope is correct.
- [ ] Purpose/category is correct.
- [ ] Primary module/platform is correct.
- [ ] Risk state is correct: READ ONLY, MAKES CHANGES, or MAKES CHANGES + DESTRUCTIVE.
- [ ] Filename is correct.
- [ ] Card checklist reflects real behavior.
- [ ] Connect command is accurate.
- [ ] Source loads from an approved same-origin path.
- [ ] Published source matches the reviewed approved file.
- [ ] COPY and SAVE actions work.
