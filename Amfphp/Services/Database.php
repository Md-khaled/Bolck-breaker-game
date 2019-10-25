<?php 

/**
 * 
 */
class Database
{
	private $conn;
	
	function __construct()
	{
		$this->conn=mysqli_connect("localhost","root","","block_game");
		// Check connection
		if ($this->conn->connect_error) {
		    return "Connection failed: " . $conn->connect_error;
		} 
		return "Connected successfully";
	}
	
	public function create($value)
	{
		
		$query="INSERT INTO users(score) VALUES('$value[0]')";
		$result=$this->conn->query($query);
		if ($result) {
			return true;
		}else
		{
			return false;
		}
	}
	public function read()
	{
		$query="SELECT MAX(score) AS maximum FROM  users LIMIT 3";
		$result=$this->conn->query($query);
		if ($result) {
			$rows= array();
			if ($result->num_rows > 0) {
				while ($row = $result->fetch_assoc()) {
					$rows[]=$row;
				}
			}else
			{
				$rows[0]['id']=0;
				$rows[0]['name']='No record';
				$rows[0]['score']='';
			}
			return $rows;
		}else
		{
			return false;
		}
	}
	
	public function update($value)
	{
		$query="UPDATE users SET fname=$value[1],lname=$value[2] WHERE id=$value[0]";
		$result=$this->conn->query($query);
		if ($result) {
			return true;
		}else
		{
			return false;
		}
	}
	public function delete($id)
	{
		$query="DELETE FROM users WHERE id=$id LIMIT 1";
		$result=$this->conn->query($query);
		if ($result) {
			return true;
		}else
		{
			return false;
		}
	}
}


 ?>