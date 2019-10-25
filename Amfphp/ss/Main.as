package  {
	
	import flash.display.MovieClip;
	import flash.media.Sound;
	import flash.net.URLRequest;
	
	
	public class Main extends MovieClip {
		
		
		public function Main() {
			var mySound:Sound = new Sound();
			mySound.load(new URLRequest("../Services/file/song.mp3"));
			
			mySound.play();
		}
	}
	
}
