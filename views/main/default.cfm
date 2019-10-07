<cfparam name="rc.homeLoans" default="#{}#">

<h1>FW/1 &amp; RuleBox</h1>

<!--- <cfdump var="#rc.homeLoans.getResult()#" label="Result Object"> --->
<cfdump var="#rc.homeLoans?.getResult()?.getDefaultValue()#" label="Default value should be 4.5">
<cfdump var="#rc.homeLoans?.getResult()?.getValue()#" label="New value should be 4.4">