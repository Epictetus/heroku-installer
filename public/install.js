window.open = function(url, name) {
  var a = document.createElement("a");
  a.href = url;
  if (name) a.target = name;
  var event = document.createEvent("MouseEvents");
  event.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 1, null);
  a.dispatchEvent(event);
  return true;
};

$(function () {
  var status = $("#status");
  var api_key = $("input[name='api_key']");
  api_key.val(localStorage.getItem("api_key") || "");

  $("form").submit(function () {
    var app_name = $("input[name='app_name']").val();
    localStorage.setItem("api_key", api_key.val());
    $("form input[type='submit']").hide();
    $("form input").attr("disabled", "disabled");
    status.show();

    var client = new XMLHttpRequest(), read = 0, returned = false;
    client.open("POST", location.href, true);
    client.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    client.addEventListener("readystatechange", function () {
      if ( this.readyState == 3 ) {
        var data = this.responseText;
        
        for ( ; read < data.length; read++ ) {
          switch (data[read]) {
            case "\033":
              read += 2;
              break;
            case "\r":
              returned = true
              break;
            case "\n":
              break;
            default:
              if (returned) {
                status.text(data[read]);
                returned = false;
              } else {
                status[0].textContent += data[read];
              }

              break;
          }
        }
      } else if ( this.readyState == 4 ) {
        window.open("http://" + app_name + ".herokuapp.com/");
      }
    });

    client.send("app_name=" + encodeURI(app_name) + "&api_key="  + encodeURI(api_key.val()));
    return false;
  });
});
