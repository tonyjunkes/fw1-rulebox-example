component extends="framework.one"
	output="false"
{
	this.applicationTimeout = createTimeSpan( 0, 2, 0, 0 );
	this.setClientCookies = true;
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan( 0, 0, 30, 0 );
	this.mappings = {
		"/logbox" = expandPath( "./subsystems/logbox" ),
		"/rulebox" = expandPath( "./subsystems/rulebox" )
	};

	// FW/1 settings
	variables.framework = {
		defaultSection: "main",
		defaultItem: "default",
		error: "main.error",
		diEngine: "di1",
		diLocations: [ "/model" ],
		diConfig: {
			transients: [ "rules" ],
			loadListener: ( di1 ) => {
				// Create an impersonation of WireBox :D
				di1.declare( "WireBox" ).asValue({
					getInstance: ( name, initArguments ) => {
						// Parse object@module to get subsystem
						var module = name.listToArray( "@" ).last();
						return getBeanFactory( module ).getBean( name, initArguments );
					}
				});
				// Pull in the root logger as a core citizen
				di1.declare( "Logger" ).asValue( getBeanFactory( "logbox" ).getBean( "LogBox" ).getRootLogger() );
			}
		},
		subsystems: {
			logbox: {
				diConfig: {
					loadListener: ( di1 ) => {
						di1.declare( "LogBoxConfig" ).instanceOf( "logbox.system.logging.config.LogBoxConfig" )
							.withOverrides( { CFCConfigPath: "conf.LogBoxConfig" } )
							.done()
							.declare( "LogBox" ).instanceOf( "logbox.system.logging.LogBox" )
							.withOverrides( { config: di1.getBean( "LogBoxConfig" ) } );
					}
				}
			},
			rulebox: {
				diLocations: [ "/models" ],
				diConfig: {
					transientPattern: "^(Rule|Result)",
					omitDirectoryAliases: true,
					loadListener: ( di1 ) => {
						// Because RuleBox's Builder CFC lacks the accessors annotation,
						// DI/1 will not inject its expected dependencies so we'll declare a custom instance
						di1.declare( "Builder" ).asValue({
							ruleBook: ( name ) => {
								return di1.getBean( "RuleBook", { name: name } );
							},
							rule: ( name ) => {
								return di1.getBean( "Rule", { name: name } );
							}
						});
						// Alias the RuleBox CFCs to match how WireBox expects them
						di1.declare( "Builder@rulebox" ).aliasFor( "Builder" )
							.done()
							.declare( "Result@rulebox" ).aliasFor( "Result" )
							.done()
							.declare( "Rule@rulebox" ).aliasFor( "Rule" )
							.done()
							.declare( "RuleBook@rulebox" ).aliasFor( "RuleBook" );
					}
				}
			}
		},
		trace: true,
		reloadApplicationOnEveryRequest: true
	};
}