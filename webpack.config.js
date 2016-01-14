module.exports = {
	entry: './src/index.cjsx',
	output: {
		filename: (process.env.WEBPACK_ENV === 'build' ? './public/bundle.js' : 'bundle.js')
	},
	module: {
		loaders: [
			{test: /\.jsx$/, loader: "jsx-loader?insertPragma=React.DOM"},
			{test: /\.cjsx$/, loaders: ["coffee", "cjsx"]},
			{test: /\.coffee$/, loader: "coffee"},
			{test: /\.json$/, loader: "json"}
		]
	},
	resolve: {
		extensions: ["", ".jsx", ".cjsx", ".coffee", ".js"],
		modulesDirectories: ["js", "node_modules"]
	}
};