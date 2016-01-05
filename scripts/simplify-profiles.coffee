# Reads profile files from ../data and strips out basic type definitions 
# and items not currently used by the editor to reduce file size.
# Saves results to ../public/profiles.json

fs = require "fs"
path = require "path"

inputFiles = ["../fhir_profiles/profiles-resources.json", "../fhir_profiles/profiles-types.json"]
outputFile = "../public/profiles.json"

profiles = {}

loadProfiles = (fhirBundle) ->
	for entry in fhirBundle?.entry || []
		root = entry?.resource?.snapshot?.element?[0]?.path
		continue unless root and 
			root[0] is root[0].toUpperCase()

		profiles[root] = {}
		for e, i in entry?.resource?.snapshot?.element || []
			profiles[root][e.path] =
				index: i
				path: e.path
				min: e.min
				max: e.max
				type: e.type
				isSummary: e.isSummary
				isModifier: e.isModifier
				short: e.short

for file in inputFiles
	fhirBundle = JSON.parse fs.readFileSync(path.join __dirname, file)
	loadProfiles(fhirBundle)

fs.writeFileSync path.join(__dirname, outputFile),
	JSON.stringify profiles, null, "  "