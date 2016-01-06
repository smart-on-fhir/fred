## Planned Features:
- Create new resources by type
- Create new bundles
- Insert resources into existing bundles
- Insert bundles into existing bundles (?)
- Remove resource from a bundle
- Validate cardinality prior to save
- Validate required elements prior to save

## Potential Features (unordered):
- Primitive type extension support
- Use files (instead of base 64 coded strings) to create attachments
- Download attachments to disk
- UI to insert element content into narrative (maybe a hidden template)
- Search / autocomplete for recognized code systems (LOINC, SNOMED, RxNorm, etc)
- Open resources from FHIR server (with some kind of search and browse functionality)
- Save resources to FHIR server
- Load and save resources/bundles on github
- Globally set patient, provider and encounter references in bundle
- Launch FRED from app and pass resource(s) through post message
- Keyboard shortcuts (position indicator, up, down, insert, edit mode, open, export)
- Re-order resources in bundle
- Collapse nested elements in UI
- Wysiwyg editor for narrative (current editors are heavy and not very good)
- Datetime editor (will have to be custom to support FHIR types and not sure this is useful)
- Insert contained resources
- Test and support recent versions of IE (probably already works with edge browser)
- Test and support tablet use

## Recent Features:
- Linked nameReference elements (like in Questionnaire resource)
