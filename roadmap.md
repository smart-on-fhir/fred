## Planned Features:
- Globally set patient, provider and encounter references in bundle
- Validate cardinality prior to save
- Validate required elements prior to save

## Potential Features (unordered):
- Use files (instead of base 64 coded strings) to create attachments
- Download attachments to disk
- Support for valuesets in codeable concepts
- Search for resource in bundle
- Re-order resources in bundle
- Primitive type extension support
- UI to insert element content into narrative (maybe a hidden template)
- Search / autocomplete for recognized code systems (LOINC, SNOMED, RxNorm, etc)
- Open resources from FHIR server (with some kind of search and browse functionality)
- Save resources to FHIR server
- Load and save resources/bundles on github
- Keyboard shortcuts (position indicator, up, down, insert, edit mode, open, export)
- Collapse nested elements in UI
- Wysiwyg editor for narrative (current editors are heavy and not very good)
- Datetime editor (will have to be custom to support FHIR types and not sure this is useful)
- Test and support recent versions of IE (probably already works with MS Edge browser)
- Test and support tablet use

## Recent Features:
- Support for simple valuesets selection and validation in codes
- Insert contained resources into resources
- Insert resources into existing bundles
- Remove resource from a bundle
- Insert bundled resources into existing bundles
- Pass in profile sets through query string (eg. DSTU2)
- Support linked nameReference elements (as in Questionnaire resource)
- Create new resources by type
- Create new bundles
- Launch FRED from app and pass resource(s) through postMessage API