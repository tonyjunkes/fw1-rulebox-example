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
		describe( "A Rule", function(){
			beforeEach(function( currentSpec ){
				initFW1App();
				rulebook = variables.fw.getBeanFactory( "rulebox" ).getBean( "rulebook@rulebox" );
			});

			it( "can be created", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "Rule@rulebox" )
					.setRuleBook( rulebook );
				expect( rule ).toBeComponent();
				expect( rule.getFacts() ).toBeEmpty();
				expect( rule.getCurrentState() ).toBe( rule.STATES.NEXT );
				expect( rule.getConsumers() ).toBeEmpty();
				expect( isClosure( rule.getPredicate() ) ).toBeTrue();
			});

			it( "can store a given fact", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.given( "name", "luis" );
				expect( rule.getFacts() ).toHaveKey( "name" );
			});

			it( "can store multiple facts", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.givenAll( { "name" : "luis" } );
				expect( rule.getFacts() ).toHaveKey( "name" );
			});

			it( "can store when functions", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.when( function( facts ){
						return false;
					} );
				expect( isClosure( rule.getPredicate() ) ).toBeTrue();
				var predicate = rule.getPredicate();
				expect( predicate() ).toBeFalse();
			});

			it( "can store then functions", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.then( function( facts ){
					} );
				expect( rule.getConsumers().len() ).toBe( 1 );
			});

			it( "can store except functions", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.except( function( facts ){
						return false;
					} );
				expect( isClosure( rule.getExcept() ) ).toBeTrue();
				var except = rule.getExcept();
				expect( except() ).toBeFalse();
			});

			it( "can stop execution chains", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.stop();
				expect( rule.getCurrentState() ).toBe( rule.STATES.STOP );
			});

			it( "can store using fact names when none are defined", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.using( "name" )
					.using( "age" );
				expect( rule.getFactsNameMap()[ 1 ].findNoCase( "name" ) ).toBeTrue();
				expect( rule.getFactsNameMap()[ 1 ].findNoCase( "age" ) ).toBeTrue();
			});

			it( "can store the next rule", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" );

				expect( rule.getNextRule() ).toBeNull();

				rule
					.setNextRule(
						variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					);
				expect( rule.getNextRule() ).toBeComponent();
			});

			it( "can run the rules when the predicate is false", function(){
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.setRuleBook( rulebook )
					.given( "name", "luis" )
					.when( function( facts ){
						return ( facts.keyExists( "age" ) );
					} )
					.run();
			});

			it( "can run the rules when the predicate is true", function(){
				var ruleResult = false;
				var rule = variables.fw.getBeanFactory( "rulebox" ).getBean( "rule@rulebox" )
					.setResult( variables.fw.getBeanFactory( "rulebox" ).getBean( "Result@rulebox" ) )
					.setRuleBook( rulebook )
					.given( "name", "luis" )
					.when( function( facts ){
						return ( facts.keyExists( "name" ) );
					} )
					.then( function( facts, results ){
						ruleResult = true;
					} )
					.run();

				expect( ruleResult ).toBeTrue();
			});
		});
	}
}
