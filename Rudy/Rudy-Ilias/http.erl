%% @doc This module handles parsing that is relevant to HTTP requests and Responses..
-module(http).

-export([parse_request/1, ok/1, get/1]).

%% @doc Parses an HTTP request to extract its components.
%% @param A client-sent request in the form of a string (RFC2616) .
%% @returns {Request, Headers, Body}
parse_request(R0) ->
    {Request, R1} = request_line(R0),
    {Headers, R2} = headers(R1),
    {Body, _} = message_body(R2),
    {Request, Headers, Body}.

%% @doc Parses an HTTP request and extracts method, URI, and version.
%% As a convention, we assume all requests are GET requests.
%% @param A client-sent request in the form of a string (RFC2616) .
%% @returns {Method, Uri, Version}
request_line([$G, $E, $T, 32 | R0]) ->
    {URI, R1} = request_uri(R0),
    {Ver, R2} = http_version(R1),
    [13, 10 | R3] = R2,
    {{get, URI, Ver}, R3}.

% TODO: make this function tail-recursive
% request_uri([32 | R0])->
%     {[], R0};
% request_uri([C|R0]) ->
%     {Rest, R1} = request_uri(R0),
%     {[C|Rest], R1}.

%% @doc Parses part of an HTTP request (after the request method) and extracts its URI.
%% @param The part of the request string after the method.
%% @returns {Uri, rest_of_request}
request_uri(Uri, [32 | R0])->
    {lists:reverse(Uri), R0};
request_uri(Uri, [C | R0]) ->
    request_uri([C | Uri], R0).
request_uri(R0) ->
    request_uri([], R0).

%% @doc Parses part of an HTTP request (after the request URI) and extracts the HTTP version.
%% As a convention, we assume all requests are HTTP/1.1 or HTTP/1.0.
%% @param The part of the request string after the URI.
%% @returns {Version, rest_of_request}
http_version([$H, $T, $T, $P, $/, $1, $., $1 | R0]) ->
    {v11, R0};
http_version([$H, $T, $T, $P, $/, $1, $., $0 | R0]) ->
    {v10, R0}.

%% @doc Parses part of an HTTP request (after the http version) and extracts the headers.
%% @param The part of the request string after the http version.
%% @returns {Headers, rest_of_request}
headers([13, 10 | R0]) ->
    {[], R0};
headers(R0) ->
    {Header, R1} = header(R0),
    {Rest, R2} = headers(R1),
    {[Header|Rest], R2}.

header([13, 10 | R0]) ->
    {[], R0};
header([C | R0]) ->
    {Rest, R1} = header(R0),
    {[C|Rest], R1}.

%% @doc Parses part of an HTTP request (after the headers) and extracts the message body.
%% As a convention, we assume that the message body is the remaining part of the request.
%% @param The part of the request string after the headers.
%% @returns {Body, []}
message_body(R) ->
    {R, []}.


%% Creates a simple HTTP response (RFC 2616) with a 200 OK status and the provided body.
%% @param A response body string.
%% @returns A complete HTTP response string.
ok(Body) ->
    "HTTP/1.1 200 OK\r\n" ++ "\r\n" ++ Body.

%% @doc Creates a simple HTTP GET request (RFC 2616) with the provided URI.
%% @param The URI for the GET request.
%% @returns A complete HTTP GET request string.
get(URI) ->
    "GET " ++ URI ++ " HTTP/1.1\r\n" ++ "\r\n".