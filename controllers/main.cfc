component name="Main Controller" accessors=true
	output=false
{
	property BeanFactory;
	property HomeLoanRateRuleBook;

	void function default( struct rc = {} ) {
		var ruleBook = variables.HomeLoanRateRuleBook;
		var applicant = variables.BeanFactory.getBean(
			"Applicant", { creditScore: 650, cashOnHand: 20000, firstTimeHomeBuyer: true }
		);
		rc.homeLoans = ruleBook
			.withDefaultResult( 4.5 )
			.given( "applicant", applicant )
			.run();
	}
}