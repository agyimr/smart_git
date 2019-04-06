import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './config.dart';

class Route {
  int to, from;
  String color;

  Route(this.from, this.to, this.color);

  factory Route.fromList(Map<String, dynamic> json) {
    return Route(json['from'], json['to'], json['color']);
  }
}

class Commit {
  String color, msg;
  int x;
  List<Route> routes;

  Commit(this.color, this.msg, this.x, this.routes);

  factory Commit.fromJson(Map<String, dynamic> json) {
    var list = (json['routes'] as List)
      .map((route) => Route.fromList(route))
      .toList();

    return Commit(json['color'], json['message'], json['x'], list);
  }
}

class OpenPainter extends CustomPainter {
  Commit commit;
  double height, width, circleTopY, circleMidX, radius = 15.0;

  OpenPainter(this.commit, this.height, this.width) {
    circleTopY = height - 2 * radius;
    circleMidX = commit.x * height + height / 2;
  }

  @override
  bool shouldRepaint(CustomPainter c) => false;

  Color getColor(String s) {
    return Color(int.parse(s, radix: 16));
  }

  Paint dim(double pos, Paint paint) {
    if (pos > width) paint.color = paint.color.withOpacity(0.3);
    return paint;
  }

  drawLine(Canvas canvas, Paint paint, Route route) {
    paint
      ..style = PaintingStyle.stroke
      ..color = getColor(route.color);
    var startY = commit.x == route.from ? circleTopY : height;
    var fromX = route.from * height + height / 2;
    var toX = route.to * height + height / 2;
    paint = dim(toX, paint);
    paint = dim(fromX, paint);
    var offset = (toX - fromX) / 3;
    var path = Path()
      ..moveTo(fromX, startY)
      ..cubicTo(fromX + offset, 0, toX - offset, height - radius * 2, toX, 0);
    canvas.drawPath(path, paint);
  }

  drawCircle(Canvas canvas, Paint paint) {
    var center = Offset(circleMidX, height - radius);
    paint.color = getColor(commit.color);
    paint = dim(circleMidX + radius, paint);
    canvas.drawCircle(center, radius, paint);
  }

  drawRects(Canvas canvas, Paint paint) {
    paint.color = getColor(commit.color);
    canvas.drawRect(Rect.fromLTRB(width - 3, circleTopY, width, height), paint);
    if (circleMidX + radius > width) return;
    paint.color = getColor(commit.color).withOpacity(0.3);
    canvas.drawRect(Rect.fromLTRB(circleMidX, circleTopY, width, height), paint);
  }

  @override
  void paint(Canvas canvas, Size s) {
    var paint = Paint()
      ..strokeWidth = 3;

    drawRects(canvas, paint);
    drawCircle(canvas, paint);
    commit.routes.forEach((route) => {
      drawLine(canvas, paint, route)
    });

    canvas.save();
    canvas.restore();
  }
}

class Main extends StatefulWidget {
  @override
  _App createState() => _App();
}

class _App extends State<Main> {
  var textC = TextEditingController();
  var _commits = List<Commit>();
  var _loading = false;
  var _msg = 'Search repository';

  _fetchCommits() async {
    var repo = textC.text;
    if (!repo.contains('/')) {
      setState(() { _commits = []; _msg = 'Invalid input'; });
      return;
    }
    setState(() { _loading = true; });

    var resp = await http.get('$apiUrl?repo=$repo');
    if (resp.statusCode == 200) {
      _commits = (json.decode(resp.body) as List)
        .map((c) => Commit.fromJson(c))
        .toList();

      setState(() { _loading = false; });
    } else setState(() { _commits = []; _msg = 'Something went wrong...'; _loading = false; });
  }

  Widget _buildLine(BuildContext ctx, Commit commit) {
    var height = 40.0;
    var maxWidth = MediaQuery.of(ctx).size.width;
    var paintWidth = maxWidth * 0.3;
    var messageWidth = maxWidth * 0.6;

    return Container( width: maxWidth, height: height,
      child: Row (children: [
        CustomPaint(
          size: Size(paintWidth, height),
          painter: OpenPainter(commit, height, paintWidth)
        ),
        Container(
          width: messageWidth,
          margin: EdgeInsets.only(left: 10, top: 10),
          child: Text(commit.msg, style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)
        )
      ])
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textC,
            decoration: InputDecoration.collapsed(hintText: 'Search repository'),
          ),
          actions: [IconButton(icon: Icon(Icons.search), onPressed: _fetchCommits)]
        ),
        body:
        _loading
          ? Center(child: CircularProgressIndicator())
          : _commits.length == 0
            ? Center(child: Text(_msg))
            : ListView.builder(
                itemBuilder: (BuildContext ctx, int i) => _buildLine(ctx, _commits[i]),
                itemCount: _commits.length)
      )
    );
  }
}

void main() => runApp(Main());