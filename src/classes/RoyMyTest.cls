public with sharing class RoyMyTest extends revvy.CMnBaseTriggerHandler {
	public RoyMyTest() {
	}
	public String getClassName() {
        //there is no way programatically find the class name of this instance
        //we will parse the result of the toString method
        return String.valueOf(this).substringBefore(':');
    }	   
}