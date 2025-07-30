## 0.12.0

- Add `append` param to all write APIs.

## 0.11.3

- Update some error messages to be more descriptive.

## 0.11.2

- Allow `start` to be null when `count` is not null in `readFileBytes`.

## 0.11.1

- More graceful handling of cancellation.

## 0.11.0

- Add custom file stream support (`startReadCustomFileStream`, `readCustomFileStreamChunk`, `skipCustomFileStreamChunk`, `endReadCustomFileStream`) to allow skipping bytes on native side.

## 0.10.2

- Fix uncaught exceptions on invalid URIs.
- Fix leaks in input streams.

## 0.10.1

- Update README.

## 0.10.0

- Deprecate `readFileSync` and `writeFileSync`. This is a non-breaking changes. `readFileBytes` and `writeFileBytes` are added to replace them. The new methods are exactly the same as the old ones. It's just a name change. Because the old names are misleading, they are not synchronous.
- Better docs.

## 0.9.0

- Migrate from `mg_shared_storage` to `saf_util`.
- Update to Gradle 8

## 0.8.1

- Fix some threading issues.

## 0.8.0

- Add `start` and `count` params to `readFileSync` and `readFileStream`.

## 0.7.5

- Fix issues when overwriting file contents

## 0.7.0

- [Breaking] Rename `readFileToLocal` and `writeFileFromLocal` to `copyToLocalFile` / `pasteLocalFile`.
- Add `readFileSync` and `writeFileSync` for synchronous file operations.

## 0.6.0

- Return `SafNewFile` in `writeFileFromLocal`.

## 0.5.0

- Add `fileName` to `SafWriteStreamInfo`.
- Fix Kotlin build issues.

## 0.4.0

- Stop using `wt` mode for newly created files

## 0.3.0

- Always create new files in `writeFileFromLocal`

## 0.1.0

- Added `readFileToLocal` and `writeFileFromLocal`

## 0.0.3

- Initial public release
