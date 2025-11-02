# Agent: ImportExportAgent

## Purpose
Import legacy individual Plant JSON files and export in native format.

## Tasks
- Map legacy fields to native models; store attachments.
- Export single plant / all plants as JSON bundle.

## Tests
- Roundtrip equality (ignoring order of optional arrays); attachment presence.
