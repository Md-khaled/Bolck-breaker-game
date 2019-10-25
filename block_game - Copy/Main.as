package 
{

	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.sensors.Accelerometer;
	import flash.events.AccelerometerEvent;
	import flash.events.MouseEvent;
	import fl.motion.MotionEvent;
	import fl.motion.Color;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.setTimeout;
	import caurina.transitions.Tweener;
	import flash.display.StageScaleMode;
	import flash.text.*;
	import flash.utils.getTimer;
	import flash.net.SharedObject;
	import flash.net.NetConnection;
	import flash.net.Responder;
	import flash.events.NetStatusEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;


	public class Main extends MovieClip
	{
		private var bg_mc:MovieClip;
		private var paddle:MovieClip;
		private var ball:MovieClip;
		private var newBrick:MovieClip;
		private var power:MovieClip;
		private var pd:MovieClip;
		private var menu:MovieClip;
		private var board:MovieClip;
		private var floorPdle:MovieClip;
		private var insectSpeed:Number = 5;
		private var accelerometer:Accelerometer;
		private var paddleXSpeed:Number = 0;
		var start_color: Color = new Color();
		private var ySpeed:Number = 0;
		private var ballXSpeed:Number = .5;//X Speed of the Ball
		private var ballYSpeed:Number = 5;
		private var newX:Number = 0;
		private var pwX:Number = 0;
		private var tmp:Number = 0;
		private var scores:Number = 0;
		private var lives:Number = 3;
		private var label1: Array = new Array();
		private var obstacles:Array;
		private var brickCount:Number = 0;
		private var totalBricks:Number = 36;
		private var currentLevel:Number = 1;
		private var row:Number = 0;
		private var col:Number = 0;
		private var shootTime:Timer;
		private var bullets:Array = [];
		private var bullet:Bullet;
		private var bullet2:Bullet2;
		/*Game time*/
		private var gameStartTime:uint;
		private var gameTime:uint;
		private var gameTimeField:TextField;
		private var powerUpText:TextField;
		var count:Number = 180;
		var clockTimer:Timer = new Timer(1000,count);
		var totalSecondsLeft:Number = 0;

		/*create local storage*/
		private var shareObj:SharedObject;
		private var highestScoreTaken:int;
		private var brickTotalScore:int;
		/*database connection*/
		private var getway_url = "http://localhost/amfphp/";
		private var gw:NetConnection;
		private var responder:Responder;
		private var gameOver:MovieClip;
		/*Create Sound*/
		private var mySound:Sound;
		private var channel:SoundChannel=new SoundChannel();
		private var soundOnOff:Boolean=false;
		

		
		public function Main()
		{

			stage.scaleMode = StageScaleMode.EXACT_FIT;
			menu=new Menu();
			stage.addChild(menu);
			menu.x=0;
			menu.y=stage.stageHeight/2;
			menu.btn_play_game.addEventListener(MouseEvent.CLICK, loadGame);
			menu.btn_continue.addEventListener(MouseEvent.CLICK, continueGame);
			menu.snd_on.visible=false;
			menu.snd_off.addEventListener(MouseEvent.MOUSE_DOWN, soundOn);
			
			//run();
		}
		private function loadGame(e:MouseEvent):void
		{
			menu.visible=false;
			menu.btn_play_game.removeEventListener(MouseEvent.CLICK, loadGame);
			
			run();
		}
		private function soundOn(e:MouseEvent):void
		{
			soundOnOff=true;
			menu.snd_off.visible=false;
			menu.snd_on.visible=true;
			menu.snd_on.addEventListener(MouseEvent.MOUSE_DOWN, soundOff);
			
		}
		private function soundOff(e:MouseEvent):void
		{
			soundOnOff=false;
			menu.snd_on.visible=false;
			menu.snd_off.visible=true;
			
		}
		private function run()
		{
			
			componentAddToStage();
			bg_mc.ball.addEventListener(Event.ENTER_FRAME, moveBallOnPaddle);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);

		}
		private function startGame(e: MouseEvent):void
		{
			//componentAddToStage();
			bg_mc.msg.visible = false;
			powerUpText.alpha = 1;
			powerUpText.text = "SIZE UP! :)";
			Tweener.addTween(powerUpText, {
			alpha: 0,
			time: 2
			});
			shareObj = SharedObject.getLocal('bock_breaker');
			if (shareObj.data['highestScore'] != undefined||shareObj.data['nextLevel']!=undefined)
			{
				highestScoreTaken = shareObj.data['highestScore'];
				//shareObj.data['nextLevel']=1;
			}
			else
			{
				shareObj.data['highestScore'] = 0;
				shareObj.data['nextLevel']=1;
				shareObj.flush(0);
			}
			trace('dfdsfs' + shareObj.data['highestScore']);
			gameStartTime = getTimer();
			gameTime = 0;
			brickTotalScore = 0;
			//gameover_mc.score_txt.text = insectTakenTotal.toString();
			clockStart();
			shootTime = new Timer(350);
			shootTime.addEventListener(TimerEvent.TIMER, shootBullet);

			if (Accelerometer.isSupported)
			{
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
				bg_mc.ball.removeEventListener(Event.ENTER_FRAME, moveBallOnPaddle);
				accelerometer = new Accelerometer();
				accelerometer.addEventListener(AccelerometerEvent.UPDATE, accUpdateHandler);
				//move paddle event;
				stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
				clockTimer.addEventListener(TimerEvent.TIMER, countdown);
				bg_mc.ball.addEventListener(Event.ENTER_FRAME, moveBall);
				addEventListener(Event.ENTER_FRAME, checkLevel);
			}
		}
		private function componentAddToStage():void
		{

			gw = new NetConnection();
			
			gw.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			gw.connect(getway_url);
			responder = new Responder(resultHandler,faultHandler);

			trace("bc"+brickCount);
			trace("bx"+ballXSpeed);
			trace("by"+ballYSpeed);
			obstacles = [];
			bg_mc = new Background();
			this.addChild(bg_mc);

			/*text field*/
			powerUpText = new TextField();
			powerUpText.defaultTextFormat = new TextFormat("Arial",13,0xFFFFFF);
			//powerUpText.textColor = 0xFFFFFF;
			powerUpText.scaleX = 2;
			powerUpText.scaleY = 2;
			powerUpText.selectable = false;
			powerUpText.x = (stage.stageWidth - 100) * .5;
			powerUpText.y = stage.stageHeight - 35;
			bg_mc.addChild(powerUpText);
			gameTimeField = new TextField();
			gameTimeField.defaultTextFormat = new TextFormat("Arial",20,0xFFFFFF);
			gameTimeField.x = 70;
			bg_mc.addChild(gameTimeField);
			gameTimeField.text = '0:00';
			bg_mc.score_txt.text = scores;
			bg_mc.msg.visible = true;
			
			createLabell();
			bg_mc.paddle.x = (stage.stageWidth - bg_mc.paddle.width) * .5;
			bg_mc.paddle.y = stage.stageHeight - bg_mc.paddle.height - 30;
			bg_mc.ball.x = (stage.stageWidth - (bg_mc.ball.width)) * .5;
			bg_mc.ball.y = stage.stageHeight - bg_mc.paddle.height - 50;
			floorPdle = new Floor();
			floorPdle.x = bg_mc.paddle.x;
			floorPdle.y = bg_mc.paddle.y + 31;
			floorPdle.name = "floorPdle";
			bg_mc.addChild(floorPdle);
			floorPdle.visible = false;
			createSound();

		}
		private function createSound():void
		{
			mySound=new PdSound();
		}
		function countdown(event: TimerEvent)
		{
			totalSecondsLeft = count - clockTimer.currentCount;
			gameTimeField.text = timeFormat(totalSecondsLeft);
			
		}
		function timeFormat(seconds: int):String
		{
			var minutes:int;
			var sMinutes:String;
			var sSeconds:String;
			if (seconds > 59)
			{
				minutes = Math.floor(seconds / 60);
				sMinutes = String(minutes);
				sSeconds = String(seconds % 60);
			}
			else
			{
				sMinutes = "00";
				sSeconds = String(seconds);
			}
			if (sSeconds.length == 1)
			{
				sSeconds = "0" + sSeconds;
			}
			return sMinutes + ":" + sSeconds;
		}
		function clockStart()
		{
			clockTimer.start();
		}
		function clockStop()
		{
			clockTimer.stop();
		}
		function resetClock()
		{
			gameTimeField.text = '0:00';
			clockTimer.reset();

		}
		private function checkLevel(event: Event):void
		{
			if (brickCount == totalBricks)
			{
				brickTotalScore=int(scores)+(lives*1000)+(totalSecondsLeft*10);
				if (brickTotalScore > highestScoreTaken)
				{
					shareObj.data['highestScore'] = brickTotalScore;
					shareObj.flush(0);
				}
				//trace('highestScore' + shareObj.data['highestScore']);
				currentLevel++;
				stopBullet();
				resetClock();
				insertData();
				//ballYSpeed *= -1;
				var numInsects:int = bullets.length;
				for (var i:int = 0; i<numInsects; i++)
				{
					trace("in frequently call fucn" );
					var ins:MovieClip = bullets[0] as MovieClip;
					bg_mc.removeChild(ins);
					bullets.splice(0,1);
				}
				//trace("frequently call fucn" );
				totalBricks +=  9;
				brickCount = 0;
				row = 0;
				col = 0;
				ballXSpeed = .5;
				ballYSpeed = 5;
				accelerometer.removeEventListener(AccelerometerEvent.UPDATE, accUpdateHandler);
				paddleXSpeed = 0;
				clockTimer.removeEventListener(TimerEvent.TIMER, countdown);
				stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				bg_mc.ball.removeEventListener(Event.ENTER_FRAME, moveBall);
				removeEventListener(Event.ENTER_FRAME, checkLevel);
				//bg_mc.ball.addEventListener(Event.ENTER_FRAME, moveBallOnPaddle);
				

				scoreBoard();
			}
		}
		private function scoreBoard():void
		{
			bg_mc.visible=false;
			gameOver=new GameOver();
			addChild(gameOver);
			gameOver.score_txt.text = scores;
			gameOver.time_txt.text = totalSecondsLeft+" * 10";
			gameOver.live_txt.text = lives+" * 1000";
			gameOver.total_txt.text =int(scores)+(lives*1000)+(totalSecondsLeft*10);
			gameOver.btn_replay.visible=false;
			gameOver.btn_next.visible=true;
			gameOver.btn_next.addEventListener(MouseEvent.CLICK, nextLevel);
			
			
		}
		private function nextLevel(event:MouseEvent):void
		{
			run();
		}
		private function createLabell():void
		{
			var rnd=Math.floor( Math.random() * totalBricks );

			for (var i: Number = 0; i < totalBricks; i++)
			{
				if (i == rnd)
				{
					newBrick = new Power();
					newBrick.name = "power";
				}
				else
				{
					newBrick = new Brick();
				}
				bg_mc.addChild(newBrick);
				newBrick.x = 50 * row + 10;
				newBrick.y = 30 * col + 40;
				label1.push(newBrick);
				if(currentLevel==1||currentLevel==2)
				{
					obstacles.push(1);
				}else
				{
					obstacles.push(0);
				}
				
				row++;
				if (row > 8)
				{
					row = 0;
					col++;
					//trace(col);
				}
				//trace(label1[i]);
			}
		}

		private final function enterFrameHandler(event: Event):void
		{
			event.stopPropagation();
			movePaddle();
		}

		private final function movePaddle():void
		{
			//trace('pp'+bg_mc.paddle.x);
			//var newX:Number =bg_mc.paddle.x + paddleXSpeed;
			newX = bg_mc.paddle.x + paddleXSpeed;
			//var newY:Number = bg_mc.paddle.y + ySpeed;

			if (newX < 8)
			{
				bg_mc.paddle.x = 8;
				paddleXSpeed = 0;
			}
			else if (newX > stage.stageWidth - bg_mc.paddle.width - 8)
			{
				bg_mc.paddle.x = stage.stageWidth - bg_mc.paddle.width - 8;
				paddleXSpeed = 0;
			}
			else
			{
				bg_mc.paddle.x +=  paddleXSpeed;
			}


		}
		private function mouseDownHandler(e: MouseEvent):void
		{
			startGame(e);

		}
		private function moveBallOnPaddle(event: Event):void
		{
			bg_mc.ball.x +=  ballXSpeed;
			
			if (bg_mc.ball.x < 300 / 2)
			{
				ballXSpeed *=  -1;
			}
			else if (bg_mc.ball.x > stage.stageWidth - 170)
			{
				ballXSpeed *=  -1;
			}


		}
		private function moveBall(event: Event):void
		{
			//trace('bb'+bg_mc.ball.x);
			bg_mc.score_txt.text = scores;
			bg_mc.live_txt.text = String('Live ' + lives);
			bg_mc.ball.x +=  ballXSpeed;
			bg_mc.ball.y -=  ballYSpeed;
			if (bg_mc.ball.x < 15)
			{
				trace('bbx'+bg_mc.ball.x);
				ballXSpeed *=  -1;
			}
			if (bg_mc.ball.x > stage.stageWidth - bg_mc.ball.width - 16)
			{
				ballXSpeed *=  -1;
				trace('bbxx'+bg_mc.ball.x);
			}
			if (bg_mc.ball.y < 40)
			{
				ballYSpeed *=  -1;
				trace('bby'+bg_mc.ball.y);
			}
			if (bg_mc.ball.hitTestObject(bg_mc.paddle))
			{
				calcBallAngle();
				if(soundOnOff)
				{
					mySound.play();
				}
				
			}
			if (bg_mc.ball.y > stage.stageHeight)
			{
				trace('bbyy'+bg_mc.ball.y);
				clockStop();
				ballYSpeed *=  -1;
				lives--;
				bg_mc.live_txt.text = String('Live ' + lives);
				if (lives >= 1)
				{
					bg_mc.paddle.x = (stage.stageWidth - bg_mc.paddle.width) * .5;
					bg_mc.paddle.y = stage.stageHeight - bg_mc.paddle.height - 30;
					bg_mc.ball.x = (stage.stageWidth - (bg_mc.ball.width)) * .5;
					bg_mc.ball.y = stage.stageHeight - bg_mc.paddle.height - 50;
					ballXSpeed = .5;
					ballYSpeed = 5;
					bg_mc.msg.visible = true;
					accelerometer.removeEventListener(AccelerometerEvent.UPDATE, accUpdateHandler);
					paddleXSpeed = 0;
					stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
					bg_mc.ball.removeEventListener(Event.ENTER_FRAME, moveBall);
					bg_mc.ball.addEventListener(Event.ENTER_FRAME, moveBallOnPaddle);
					stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);



				}
				else if (lives < 1||(lives < 1&& currentLevel==4))
				{
					brickTotalScore=int(scores)+(lives*1000)+(totalSecondsLeft*10);
					if (brickTotalScore > highestScoreTaken)
					{
						shareObj.data['highestScore'] = brickTotalScore;
						shareObj.flush(0);
					}

					row = 0;
					col = 0;
					//lives = 2;
					ballXSpeed = .5;
					ballYSpeed = 5;
					paddleXSpeed = 0;
					stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
					bg_mc.ball.removeEventListener(Event.ENTER_FRAME, moveBall);
					insertData();
					readData();
					bg_mc.visible=false;
					board=new Label_board();
					addChild(board);
					board.score_txt.text=shareObj.data['highestScore'];
					board.btn_next.visible=false;
					board.btn_replay.addEventListener(MouseEvent.CLICK, replayGame);
			
					//run();

				}


			}

			collisionDetectionn();


		}
		private function continueGame(event:MouseEvent):void
		{
			menu.visible=false;
			totalBricks+=9;
			
			run();
		}
		private function replayGame(event:MouseEvent):void
		{
			
				lives=3;
				scores=0;
				
				resetClock();
				var reomove_brick:int = label1.length;
				for (var i:int = 0; i<reomove_brick; i++)
				{
					//trace("in frequently call fucn" );
					var bk:MovieClip = label1[0] as MovieClip;
					bg_mc.removeChild(bk);
					label1.splice(0,1);
					obstacles.splice(0,1);
				}
				
				brickCount = 0;
				row = 0;
				col = 0;
				ballXSpeed = .5;
				ballYSpeed = 5;
				accelerometer.removeEventListener(AccelerometerEvent.UPDATE, accUpdateHandler);
				paddleXSpeed = 0;
				clockTimer.removeEventListener(TimerEvent.TIMER, countdown);
				stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				bg_mc.ball.removeEventListener(Event.ENTER_FRAME, moveBall);
				
			run();
		}
		private function collisionDetectionn():void
		{
			var d:Number = 0;

			if (bg_mc.contains(floorPdle) && floorPdle.visible == true)
			{
				if (bg_mc.ball.hitTestObject(floorPdle))
				{
					ballYSpeed *=  -1;
					d = 1;
					bg_mc.removeChild(floorPdle);
				}

			}
			for (var i: Number = 0; i < label1.length; i++)
			{
				var bk:MovieClip = label1[i] as MovieClip;
				if (bg_mc.ball.hitTestObject(bk) && bk.name == "power")
				{
					d = 1;
					ballYSpeed *=  -1;
					brickCount++;
					scores +=  5;
					bk.parent.removeChild(bk);
					obstacles.splice(i, 1);
					label1.splice(i, 1);
					i--;
					pd = new Bullet();
					pd.x = bk.x;
					pd.y = bk.y;
					bg_mc.addChild(pd);
					pd.addEventListener(Event.ENTER_FRAME, movePower);


				}


				if (bg_mc.ball.hitTestObject(bk) && obstacles[i] == 0 && bk.name != "power")
				{

					obstacles[i] = 1;
					start_color.setTint(0xFF0000, 0.5);
					label1[i].transform.colorTransform = start_color;
					//trace('bk' + bk.name);
					ballYSpeed *=  -1;


				}
				else if (bg_mc.ball.hitTestObject(bk) && obstacles[i] == 1)
				{

					ballYSpeed *=  -1;
					brickCount++;
					scores +=  5;
					brickTotalScore +=  5;
					bk.parent.removeChild(bk);
					obstacles.splice(i, 1);
					label1.splice(i, 1);
					i--;
				}
			}
		}

		private function movePower(event: Event):void
		{
			pd.y +=  insectSpeed;
			var i:int;
			if (bg_mc.paddle.hitTestObject(pd))
			{
				if(currentLevel==1)
				{
					Tweener.addTween(bg_mc.paddle,{width:bg_mc.paddle.width-10, time:2});
					powerUpText.alpha = 1;
					powerUpText.text = "SIZE DOWN! :(";
					addChild(powerUpText);
					Tweener.addTween(powerUpText,{alpha:0, time:2});
				}
				if(currentLevel==2)
				{
					floorPdle.visible = true;
					Tweener.addTween(floorPdle,{width:floorPdle.width+(stage.stageWidth), time:.5});
				}
				if(currentLevel==3)
				{
					starShooterTime();
					stage.addEventListener(Event.ENTER_FRAME, mainLoop);
					stopShooterTime();
				}
			}
		}
		private function stopShooterTime():void
		{
			setTimeout(stopBullet, 6000);

		}
		private function stopBullet():void
		{
			shootTime.stop();
		}
		//trace('stop');

		private function starShooterTime():void
		{
			shootTime.start();

		}
		private function mainLoop(event: Event):void
		{
			
			for (var j: int = 0; j < bullets.length; j++)
			{
				var bm:MovieClip = bullets[j] as MovieClip;
				bm.y -=  5;
				for (var i: Number = 0; i < label1.length; i++)
				{
					var bk:MovieClip = label1[i] as MovieClip;
					if (bm.hitTestObject(bk))
					{
						brickCount++;
						scores +=  5;
						bm.parent.removeChild(bm);
						bk.parent.removeChild(bk);

						bullets.splice(j, 1);
						label1.splice(i, 1);
						j--;
						i--;
					}

				}

			}
		}
		private function shootBullet(e: TimerEvent):void
		{

			bullet = new Bullet();
			bullet.x = bg_mc.paddle.x;
			bullet.y = bg_mc.paddle.y - 13;
			bg_mc.addChild(bullet);
			bullets.push(bullet);
			bullet2 = new Bullet2();
			bullet2.x = bg_mc.paddle.x + 100;
			bullet2.y = bg_mc.paddle.y - 13;
			bg_mc.addChild(bullet2);
			bullets.push(bullet2);
		}
		private function calcBallAngle():void
		{
			var ballPosition:Number = bg_mc.ball.x - bg_mc.paddle.x;
			var hitPercent: Number = (ballPosition / (bg_mc.paddle.width - bg_mc.ball.width)) - .5;

			var bb = bg_mc.paddle.width - bg_mc.ball.width;

			ballXSpeed = hitPercent * 10;

			ballYSpeed *=  -1;

			//trace('ballYSpeed '+ballPosition)
		}
		private function insertData():void
		{
			var param:Array;
			var total:Number=int(scores)+(lives*1000)+(totalSecondsLeft*10);
			param = [scores];
			trace(param);
			gw.call('Database.create',responder,param);

		}
		private function readData():void
		{
			responder = new Responder(displayDataHandler,faultHandler);
			gw.call('Database.read',responder);
		}
		private function displayDataHandler(e:Object):void
		{
			if (e==false)
			{
				board.status_txt.text = "Error readin record";
			}
			else
			{
				
				board.score_txt.text = e[0]["maximum"];
				
			}
		}
		private function resultHandler(e:Object):void
		{
			if (e==true)
			{
				trace('record created successfully');
				//gameOver.status_txt.text = 'record created successfully';
			}
			else
			{
				
				trace('record not created ');
				//gameOver.status_txt.text = 'record not created ';
			}
		}
		private function faultHandler(e:Object):void
		{
			//trace("id"+e);
			gameOver.status_txt.text = String(e.description);
		}
		private function onNetStatus(event:NetStatusEvent):void
		{
			trace("i am here"+event.info);
		}
		private final function accUpdateHandler(event: AccelerometerEvent):void
		{
			paddleXSpeed -=  event.accelerationX * 2;
			ySpeed +=  event.accelerationY * 2;
		}

	}

}