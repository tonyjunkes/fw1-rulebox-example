component extends="testbox.system.BaseSpec" {
	function __config() {
		return variables.framework;
	}

	function initFW1App() {
		// Reset the framework instance before each spec is run
		request.delete( "_fw1" );
		variables.fw = new framework.one();
		variables.fw.__config = __config;
		variables.fw.__config().append({
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
							return variables.fw.getBeanFactory( module ).getBean( name, initArguments );
						}
					});
					// Pull in the root logger as a core citizen
					di1.declare( "Logger" ).asValue( variables.fw.getBeanFactory( "logbox" ).getBean( "LogBox" ).getRootLogger() );
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
						// Because FW/1 assumes objects as singletons by default,
						// we must define transients outside of convention
						transientPattern: "^(Rule|Result)",
						// Alias the RuleBox CFCs to match how WireBox expects them
						singulars: { models: "@rulebox" },
						loadListener: ( di1 ) => {
							// Because RuleBox's Builder CFC lacks the accessors annotation,
							// DI/1 will not inject its expected dependencies so we'll declare a custom instance
							di1.declare( "Builder@rulebox" ).asValue({
								ruleBook: ( name ) => {
									return di1.getBean( "RuleBook", { name: name } );
								},
								rule: ( name ) => {
									return di1.getBean( "Rule", { name: name } );
								}
							});
						}
					}
				}
			}
		});
		variables.fw.onApplicationStart();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "Rule Book Builder", function(){
			beforeEach(function( currentSpec ) {
				initFW1App();
			});

			it( "can build a rulebook", function(){
				var ruleBook = variables.fw.getBeanFactory( "rulebox" ).getBean( "Builder@rulebox" ).ruleBook( "my-rulebook" );
				expect(	ruleBook ).toBeComponent();
				expect( ruleBook.getName() ).toBe( "my-rulebook" );
			});

			it( "can build rules", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "Builder@rulebox" ).rule( "my-rule" );
				expect(	rule ).toBeComponent();
				expect( rule.getName() ).toBe( "my-rule" );
			});
		});
	}
}
