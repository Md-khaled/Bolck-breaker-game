<?php 

/**
 * 
 */
class Session
{
	
	function __construct(argument)
	{
		if (!isset($_SESSION['count'])) {
			$_SESSION['count']=0; 
		}
	}
}


 ?>