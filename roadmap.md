## Planned Features:
- Insert resources into existing bundles
- Remove resources from a bundle
- Insert bundled resources into existing bundles
- Validate cardinality prior to save
- Validate required elements prior to save

## Potential Features (unordered):
- Primitive type extension support
- Use files (instead of base 64 coded strings) to create attachments
- Download attachments to disk
- UI to insert element content into narrative (maybe a hidden template)
- Search for resource in bundle
- Search / autocomplete for recognized code systems (LOINC, SNOMED, RxNorm, etc)
- Open resources from FHIR server (with some kind of search and browse functionality)
- Save resources to FHIR server
- Load and save resources/bundles on github
- Globally set patient, provider and encounter references in bundle
- Keyboard shortcuts (position indicator, up, down, insert, edit mode, open, export)
- Re-order resources in bundle
- Collapse nested elements in UI
- Wysiwyg editor for narrative (current editors are heavy and not very good)
- Datetime editor (will have to be custom to support FHIR types and not sure this is useful)
- Insert contained resources
- Test and support recent versions of IE (probably already works with MS Edge browser)
- Test and support tablet use

## Recent Features:
- Pass in profile sets through query string (eg. DSTU2)
- Support linked nameReference elements (as in Questionnaire resource)
- Create new resources by type
- Create new bundles
- Launch FRED from app and pass resource(s) through postMessage API