var FileChanger = require("webpack-file-changer");
var fs = require("fs");
var path = require("path");

getPlugins = function() {
	var optionsDev = {
		change: [{
			file: path.join(__dirname, './public/index.html'),
			parameters: {'bundle\.(.+)\.js': 'bundle.js'}
		}]		
	}
	var optionsBuild = {
		change: [{
			file: './public/index.html',
			parameters: {
				'bundle(\..+)?\.js': 'bundle.[renderedHash:0].js'
			},
			// delete all but most recent bundle
			before: function(stats, change) {
				var dir = './public/';
				var files = fs.readdirSync(dir)
					.filter(function (name) { return /bundle\.(.+)\.js/.test(name) } )
					.sort(function(a, b) {
						return fs.statSync(path.join(dir, b)).mtime.getTime() -
							fs.statSync(path.join(dir, a)).mtime.getTime();
					})
					.forEach(function(name, i) {
						if (i > 0) fs.unlinkSync(path.join(dir, name))
					})
				return true;
			}
		}]
	};
	var options = process.env.WEBPACK_ENV === 'build' ? optionsBuild : optionsDev;
	return [ new FileChanger(options) ]
};

module.exports = {
	entry: './src/index.cjsx',
	plugins: getPlugins(),
	output: {
		filename: (process.env.WEBPACK_ENV === 'build' ? './public/bundle.[chunkhash].js' : 'bundle.js')
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