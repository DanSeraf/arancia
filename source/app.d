import std.stdio;
import vibe.vibe;
import std.conv;
import std.range;
import std.algorithm;
import sumtype;

void main()
{
    startServer();
}

struct Play {};
struct Search {};
struct Idle {};
struct Error {};

alias Action = SumType!(Play, Search, Idle, Error);

Action handleAction(string msg)
{
    switch(msg) {
    case "play": return Action(Play());
    case "search": return Action(Search());
    default: return Action(Error());
    }
}

void handleConn(scope WebSocket sock)
{
    Action action = Idle();
    while (sock.connected) {
        if (sock.waitForData()) {
            auto msg = sock.receiveText();
            writeln(msg);
            action = handleAction(msg);
        } 
        action.match!((Play p) {
                sock.send("cioa");
                action = Idle();
            },
            (Search s) {
                sock.send("search");
                action = Idle();
            },
            (Idle i) {},
            (Error e) {sock.close();}
            );
    }
}

void startServer()
{
    import vibe.http.router;
    auto router = new URLRouter;
    router.get("/ws", handleWebSockets(&handleConn));
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    listenHTTP(settings, router);
    runApplication();
}
