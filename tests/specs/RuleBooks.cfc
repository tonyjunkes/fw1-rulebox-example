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
			}
		});
		variables.fw.onApplicationStart();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "Hello World Rules", function(){
			beforeEach(function( currentSpec ) {
				initFW1App();
			});

			it( "Can run the hello world rules", function(){
				var helloRules = variables.fw.getBeanFactory().getBean( "HelloWorld" )
					.given( "hello", "Hello" )
					.given( "disabled", false );
				helloRules.run();

				expect( helloRules.getResult().getValue() ).toBe( 1 );
			});

			it( "can stop when using exceptions", function(){
				var helloRules = variables.fw.getBeanFactory().getBean( "HelloWorld" )
					.given( "hello", "Hello" )
					.given( "disabled", true );
				helloRules.run();

				expect( helloRules.getResult().isPresent() ).toBeFalse();
			});
		});

		describe( "Home Loan Rate Rules", function(){
			beforeEach(function( currentSpec ) {
				initFW1App();
			});

			it( "Can calculate a first time home buyer with 20,000 down and 650 credit score", function(){
				var homeLoans = variables.fw.getBeanFactory().getBean( "HomeLoanRateRuleBook" )
					.withDefaultResult( 4.5 )
					.given( "applicant", new tests.resources.Applicant( 650, 20000, true ) );

				homeLoans.run();

				expect( homeLoans.getResult().isPresent() ).toBeTrue();
				expect( homeLoans.getResult().getValue() ).toBe( 4.4 );
			});

			it( "Can calculate a non first home buyer with 20,000 down and 650 credit score", function(){
				var homeLoans = variables.fw.getBeanFactory().getBean( "HomeLoanRateRuleBook" )
					.withDefaultResult( 4.5 )
					.given( "applicant", new tests.resources.Applicant( 650, 20000, false ) );

				homeLoans.run();

				expect( homeLoans.getResult().isPresent() ).toBeTrue();
				expect( homeLoans.getResult().getValue() ).toBe( 5.5 );
			});
		});
	}
}
