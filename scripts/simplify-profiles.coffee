# Reads profile files from ../fhir_profiles/{title} and strips out basic type definitions 
# and items not currently used by the editor to reduce file size.

fs = require "fs"
path = require "path"

inputPath = "../fhir_profiles"
outputPath = "../public/profiles"

summarizeDirectory = (inputDirName, inputDirPath, outputDirPath) ->
	console.log "Processing #{inputDirName}"
	profiles = {}
	valuesets = {}
	
	for bundleFileName in fs.readdirSync(inputDirPath).sort()
		continue unless bundleFileName.indexOf("json") > -1
		bundleFilePath = path.join(inputDirPath, bundleFileName)
		bundle = JSON.parse fs.readFileSync(bundleFilePath)

		if bundleFileName.indexOf("valuesets") > -1 
			summarizeValuesets(bundle, valuesets)
		else if bundleFileName.indexOf("profiles") > -1
			summarizeProfiles(bundle, profiles)

	fs.writeFileSync path.join(outputDirPath, "#{inputDirName}.json"),
		JSON.stringify {profiles: profiles, valuesets: valuesets}, null, "  "

summarizeValuesets = (fhirBundle, valuesets) ->
	dstu2 = (entry) ->
		url = entry?.resource?.url
		#are they all complete?
		valuesets[url] = {type: "complete", items: []}
		for c, i in entry?.resource?.codeSystem?.concept || []
			valuesets[url].items.push [c.display, c.code]


	stu3 = (entry) -> 
		url = entry?.resource?.valueSet		
		valuesets[url] = {type: entry.resource.content, items: []}

		for c, i in entry?.resource?.concept || []
			valuesets[url].items.push [c.display, c.code]

	for entry in fhirBundle?.entry || []
		if entry?.resource?.valueSet and entry?.resource?.concept?.length > 0
			stu3(entry)
		else if entry?.resource?.url and entry?.resource?.codeSystem?.concept?.length > 0
			dstu2(entry)

	return valuesets

summarizeProfiles = (fhirBundle, profiles) ->
	for entry in fhirBundle?.entry || []
		root = entry?.resource?.snapshot?.element?[0]?.path
		continue unless root and 
			root[0] is root[0].toUpperCase()

		ids = {}
		names = {}

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
				name: e.name

			if url = e?.binding?.valueSetReference?.reference
				profiles[root][e.path].binding =
					strength: e.binding.strength
					reference: url

			#assumes id appears before reference - is this accurate?
			if e.id then ids[e.id] = e.path
			if e.name then names[e.name] = e.path

			#STU3
			if e.contentReference
				id = e.contentReference.split("#")[1]
				profiles[root][e.path].refSchema = ids[id]
			#DSTU2
			else if e.nameReference
				profiles[root][e.path].refSchema = names[e.nameReference]

	return profiles

for inputDirName in fs.readdirSync path.join(__dirname, inputPath)
	inputDirPath = path.join(__dirname, inputPath, inputDirName)
	outputDirPath = path.join(__dirname, outputPath)
	if fs.lstatSync(inputDirPath).isDirectory()
		summarizeDirectory(inputDirName, inputDirPath, outputDirPath)









