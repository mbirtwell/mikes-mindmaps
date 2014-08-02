import 'dart:html';

void main() {
  querySelector("#sample_text_id")
      ..text = "Dart stole it from me!!!"
      ..onClick.listen(reverseText);
  new WebSocket("ws://127.0.0.1:4040/stream").onMessage.listen((MessageEvent msg) {
    querySelector("#notes_container").append(new ParagraphElement()
                                            ..appendText(msg.data));

  });
}

void reverseText(MouseEvent event) {
  var text = querySelector("#sample_text_id").text;
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  querySelector("#sample_text_id").text = buffer.toString();
}
