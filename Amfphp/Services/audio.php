<?php include 'Database.php'; ?>
<form  method='post' enctype="multipart/form-data">
Description of File: <input type="text" name="description_entered"/><br><br>
<input type="file" name="audio_file"/><br><br>
	
<input type="submit" name="submit" value="Upload"/>

</form>
<?php 

$conn=mysqli_connect("localhost","root","","block_game");
if ($conn->connect_error) {
		    die("Connection failed: " . $conn->connect_error);
		}else
		{
 echo "New record created successfully";
		}
if(isset($_POST['submit']))
{
$file_name = $_FILES['audio_file']['name'];
$description= $_POST['description_entered'];

if($_FILES['audio_file']['type']=='audio/mpeg' || $_FILES['audio_file']['type']=='audio/mpeg3' || $_FILES['audio_file']['type']=='audio/x-mpeg3' || $_FILES['audio_file']['type']=='audio/mp3' || $_FILES['audio_file']['type']=='audio/x-wav' || $_FILES['audio_file']['type']=='audio/wav')
{ 
 $new_file_name=$_FILES['audio_file']['name'];

 // Where the file is going to be placed
 $target_path = "file/".$new_file_name;
 //$target_path = "D:/soundTest/file/".$new_file_name;
 
 //target path where u want to store file.

  //following function will move uploaded file to audios folder. 
if(move_uploaded_file($_FILES['audio_file']['tmp_name'], $target_path)) {

		$query="INSERT INTO files(description, filename) VALUES('$description','$new_file_name')";
		$result=$conn->query($query);
		if ($result) {
			echo 'Uploaded!';
		}else
		{
			echo 'not Uploaded!';
		}

  //insert query if u want to insert file
}
$query="SELECT * FROM files";
$result=$conn->query($query);
if ($result->num_rows > 0) {
echo 'ok!';
echo "<table border=1>\n"; 
while($row = $result->fetch_assoc()) {
$files_field= $row['filename'];
$files_show= "file/$files_field";
//$files_show= "D:/soundTest/file/$files_field";
$descriptionvalue= $row['description'];
echo "<tr>\n"; 
echo "\t<td>\n"; 
echo "<font face=arial size=4/>$descriptionvalue</font>";
echo "</td>\n";
echo "\t<td>\n"; 
echo "<div align=center><audio controls>
  <source src='$files_show' type='audio/wav'>
  
Your browser does not support the audio element.
</audio></div>";
echo "</td>\n";
echo "</tr>\n"; 
} 
echo "</table>\n"; 

}
}
}
/*
https://stackoverflow.com/questions/22855443/how-to-retrieve-and-show-images-from-another-drive-using-src-attribute-in-img (for image)
*/
?>