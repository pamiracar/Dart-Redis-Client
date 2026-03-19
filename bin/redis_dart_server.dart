import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:redis/redis.dart';

late Command redis;

void main() async {
  try {
    final conn = RedisConnection();
    redis = await conn.connect("localhost", 6379);
    print("Redis bağlandı");
  } catch (e) {
    print("hata: $e");
  }

  Future<Response> router(Request request) async {
    final path = request.url.path;

    if (path == "set") {
      final key = request.url.queryParameters["key"];
      final value = request.url.queryParameters["value"];
      if (key != null && value != null) {
        await redis.send_object(["SET", key, value]);
        return Response.ok(
          jsonEncode({"status": "ok", "msg": "$key kaydedildi"}),
        );
      }
    }
    if (path == "get") {
      final key = request.url.queryParameters["key"];
      final result = await redis.send_object(["GET", key]);
      return Response.ok(
        jsonEncode({
          "key": key,
          "value": result
        }),
        headers: {
          "content-type": "application/json"
        }
      ); 
    }
    return Response.notFound("Geçersiz İstek!");
  }

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);
  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print("Backend yayında: ${server.address.host}:${server.port}");
}
