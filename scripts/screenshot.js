function secondsToHMS(seconds) {
  var hours = Math.floor(seconds / 3600);
  var minutes = Math.floor((seconds % 3600) / 60);
  var secondsWithoutMinutes = seconds - (hours * 3600 + minutes * 60);
  var milliseconds = Math.round((secondsWithoutMinutes % 1) * 1000);

  var timeString =
    padZero(hours) +
    "-" +
    padZero(minutes) +
    "-" +
    padZero(secondsWithoutMinutes.toFixed(0));
  timeString +=
    "." +
    (milliseconds < 100 ? "0" : "") +
    (milliseconds < 10 ? "0" : "") +
    milliseconds;

  return timeString;
}

function padZero(num) {
  return (num < 10 ? "0" : "") + num;
}
// Function to save screenshots in the same directory as the video
function saveScreenshot() {
  var videoPath = mp.get_property("path");

  if (!videoPath || videoPath === "") {
    mp.msg.warn("No video path available.");
    return;
  }

  var videoDirectory = videoPath.substring(0, videoPath.lastIndexOf("/"));
  var videoFilename = mp.get_property("filename");
  var screenshotName =
    "mpv-" +
    videoFilename +
    secondsToHMS(mp.get_property("playback-time")) +
    ".jpg";

  var screenshotPath = videoDirectory + "/" + screenshotName;

  mp.commandv("screenshot-to-file", screenshotPath);
  mp.osd_message("Screenshot saved: " + screenshotPath, 2);
}

// Bind the "S" key to the saveScreenshot function
mp.add_key_binding("S", "saveScreenshot", saveScreenshot);
