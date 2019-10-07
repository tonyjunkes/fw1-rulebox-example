component {
	this.name = "FW1RuleBoxTestingSuite" & hash( getCurrentTemplatePath() );
	variables.testsPath = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings = {
		"/tests": variables.testsPath,
		"/testbox": variables.testsPath & "../testbox",
		"/framework": variables.testsPath & "../framework",
		"/model": variables.testsPath & "/resources",
		"/logbox": variables.testsPath & "../subsystems/logbox",
		"/rulebox": variables.testsPath & "../subsystems/rulebox",
		// This is to fake the subsystem location
		"/tests/subsystems/rulebox": variables.testsPath & "../subsystems/rulebox"
	};
}