package;

import electron.main.App;
import electron.main.BrowserWindow;
import electron.CrashReporter;

import electron.main.IpcMain;
import electron.main.Dialog;

import js.Node;
import js.node.Fs;

import model.constant.Channel;

class Main {


	// Keep a global reference of the window object, if you don't, the window will
	// be closed automatically when the JavaScript object is garbage collected.
	public var mainWindow : BrowserWindow = null;

	function new (){
		electron.CrashReporter.start({
			companyName : "Monk Markdown Editor",
			submitURL : "https://github.com/MatthijsKamstra/hx-markdown-editor/issues"
		});


		// Quit when all windows are closed.
		App.on( 'window_all_closed', function(e) {
			// On OS X it is common for applications and their menu bar
			// to stay active until the user quits explicitly with Cmd + Q
			if (Node.process.platform != 'darwin')
				App.quit();
		});

		// This method will be called when Electron has finished
		// initialization and is ready to create browser windows.
		App.on( 'ready', function(e) {
			// Create the browser window.
			mainWindow = new BrowserWindow({
				width: 1200,
        		height: 800,
				backgroundColor: '#2e2c29',
				// frame: false,
				titleBarStyle: 'hidden'
			});

			// Emitted when the window is closed.
			mainWindow.on( closed, function() {
				if( js.Node.process.platform != 'darwin' )
					electron.main.App.quit();
				// Dereference the window object, usually you would store windows
				// in an array if your app supports multi windows, this is the time
				// when you should delete the corresponding element.
				mainWindow = null;
			});

			// Open the DevTools.
			// mainWindow.webContents.openDevTools();

			// and load the index.html of the app.
			mainWindow.loadURL('file://' + js.Node.__dirname + '/index.html');
			// mainWindow.loadURL( 'file://' + js.Node.__dirname + '/app.html' );
			// mainWindow.loadURL('http://localhost:3000');

			// win.loadURL( 'file://' + js.Node.__dirname + '/index.html' );


			// GlobalShortcut.register('CommandOrControl+X', function () {
			// 	console.log('CommandOrControl+X is pressed');
			// });
			// GlobalShortcut.register('CommandOrControl+S', function () {
			// 	console.log('CommandOrControl+S is pressed');
			// });

			// GlobalShortcut.register('CommandOrControl+X', function (){
			// 	trace('CommandOrControl+X is pressed');
			// });
			// // Check whether a shortcut is registered.
			// console.log(GlobalShortcut.isRegistered('CommandOrControl+X'));

			// IpcMain.on('show-dialog', function (event, type:Dynamic) {
			// 	Dialog.showMessageBox(mainWindow, {
			// 		type: type,
			// 		message: 'Hello, how are you?'
			// 	});
			// });

			new MainMenu(this);

			IpcMain.on('test', function (event, test) {
				var content = "Some text to save into the file";

				// // You can obviously give a direct path without use the dialog (C:/Program Files/path/myfileexample.txt)
				// Dialog.showSaveDialog( function (fileName) {
				// 	if (fileName == null){
				// 		trace("You didn't save the file");
				// 		return;
				// 	}

				// 	// fileName is a string that contains the path and filename created in the save file dialog.
				// 	Fs.writeFile(fileName, content, function  (err) {
				// 		if(err != null){
				// 			trace("An error ocurred creating the file "+ err.message);
				// 		}

				// 		trace("The file has been succesfully saved");
				// 	});
				// });
			});

			IpcMain.on(Channel.OPEN_DIALOG, function (event){
				onOpenDialogHandler(event);
			});

			IpcMain.on(Channel.SAVE_FILE, function (event, filepath, content){
				onSaveFileHandler(event, filepath, content);
			});
			IpcMain.on(Channel.SAVE_AS_FILE, function (event, filepath, content){
				// onSaveFileHandler(event, filepath, content);
				onSaveAsFileHandler(event, filepath, content);
				trace('yep');
			});



			IpcMain.on('asynchronous-message', function(event, arg) {
				trace(arg);  // prints "ping"
				// console.log(arg);  // prints "ping"
				event.sender.send('asynchronous-reply', 'pong');
			});

			IpcMain.on('synchronous-message', function(event, arg) {
				trace(arg);  // prints "ping"
				// console.log(arg);  // prints "ping"
				event.returnValue = 'pong';
			});


			IpcMain.on('doorBell', function(event, arg) {
				trace(arg); // 'ding'
				// console.log(arg); // 'ding'
				// trace(event);
				event.returnValue = 'dong';
			});



		});


	}

	public function onOpenDialogHandler (event){
		Dialog.showOpenDialog({}, function (fileNames) {
			// fileNames is an array that contains all the selected

			trace(fileNames);

			if(fileNames == null){
				trace("No file selected");
				return;
			}

			var filepath = fileNames[0];

			Fs.readFile(filepath, 'utf-8', function (err, data) {
				if(err != null){
					trace("An error ocurred reading the file :" + err.message);
					return;
				}

				// Change how to handle the file content
				// trace("The file content is : " + data);
				if(event != null)
					event.sender.send(Channel.SEND_FILE_CONTENT, filepath, data);
				else
					this.mainWindow.webContents.send(Channel.SEND_FILE_CONTENT, filepath, data);
			});
		});
	}

	public function onSaveFileHandler(event:Dynamic, filepath:String, content:String){
		trace(filepath,content);
		Fs.writeFile(filepath, content, function (err) {
			if (err != null) {
				trace("An error ocurred updating the file" + err.message);
				trace(err);
				return;
			}
			trace("The file has been succesfully saved");
			this.mainWindow.webContents.send(Channel.SEND_FILE_PATH, filepath);
		});
	}

	public function onSaveAsFileHandler(event:Dynamic, filepath:String, content:String){
		Dialog.showSaveDialog(mainWindow, {
			title: '_foo',
			defaultPath: '~/_foo.md'
		}, function (result) {
			trace('$result');
			onSaveFileHandler(null, result, content);
		});
	}

	static function main() {
		new Main();
	}

}