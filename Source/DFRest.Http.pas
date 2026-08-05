unit DFRest.Http;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  HTTP yardimcilari (THTTPClient)                                             }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  System.Generics.Collections,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding,
  DFRest.Types,
  DFRest.Settings,
  DFRest.Exceptions;

type
  TDFRestHttpResult = record
    StatusCode: Integer;
    ReasonPhrase: string;
    Content: string;
    Url: string;
    Headers: TStringList;
    procedure Init;
    procedure FreeHeaders;
  end;

  TDFRestHttp = class
  public
    class function JoinUrl(const ABaseUrl, ARelative: string): string; static;
    class function EncodePathSegment(const AValue: string): string; static;
    class function EncodeQueryValue(const AValue: string): string; static;
    class function ReplacePathTokens(const APath: string;
      ATokens: TDictionary<string, string>): string; static;
    class function AppendQuery(const APath: string;
      AQuery: TDictionary<string, string>): string; static;
    class function Execute(AMethod: TDFRestHttpMethod; const AUrl, ABody: string;
      AHeaders: TDictionary<string, string>; ASettings: TDFRestSettings): TDFRestHttpResult; static;
  end;

implementation

procedure TDFRestHttpResult.Init;
begin
  StatusCode := 0;
  ReasonPhrase := '';
  Content := '';
  Url := '';
  Headers := TStringList.Create;
end;

procedure TDFRestHttpResult.FreeHeaders;
begin
  FreeAndNil(Headers);
end;

{ TDFRestHttp }

class function TDFRestHttp.JoinUrl(const ABaseUrl, ARelative: string): string;
var
  Base, Rel: string;
begin
  Base := Trim(ABaseUrl);
  Rel := Trim(ARelative);
  if Rel = '' then
    Exit(Base);
  if (Pos('://', Rel) > 0) then
    Exit(Rel);
  if (Base <> '') and (Base[Length(Base)] = '/') then
    Delete(Base, Length(Base), 1);
  if (Rel <> '') and (Rel[1] <> '/') then
    Rel := '/' + Rel;
  Result := Base + Rel;
end;

class function TDFRestHttp.EncodePathSegment(const AValue: string): string;
begin
  Result := TNetEncoding.URL.Encode(AValue);
end;

class function TDFRestHttp.EncodeQueryValue(const AValue: string): string;
begin
  Result := TNetEncoding.URL.Encode(AValue);
end;

class function TDFRestHttp.ReplacePathTokens(const APath: string;
  ATokens: TDictionary<string, string>): string;
var
  Pair: TPair<string, string>;
  Key: string;
begin
  Result := APath;
  if ATokens = nil then
    Exit;
  for Pair in ATokens do
  begin
    Key := '{' + Pair.Key + '}';
    Result := StringReplace(Result, Key, EncodePathSegment(Pair.Value),
      [rfReplaceAll, rfIgnoreCase]);
  end;
end;

class function TDFRestHttp.AppendQuery(const APath: string;
  AQuery: TDictionary<string, string>): string;
var
  Pair: TPair<string, string>;
  Parts: TStringList;
  I: Integer;
  Sep: string;
begin
  Result := APath;
  if (AQuery = nil) or (AQuery.Count = 0) then
    Exit;
  Parts := TStringList.Create;
  try
    for Pair in AQuery do
      Parts.Add(EncodeQueryValue(Pair.Key) + '=' + EncodeQueryValue(Pair.Value));
    if Pos('?', Result) > 0 then
      Sep := '&'
    else
      Sep := '?';
    for I := 0 to Parts.Count - 1 do
    begin
      if I = 0 then
        Result := Result + Sep + Parts[I]
      else
        Result := Result + '&' + Parts[I];
    end;
  finally
    Parts.Free;
  end;
end;

class function TDFRestHttp.Execute(AMethod: TDFRestHttpMethod; const AUrl, ABody: string;
  AHeaders: TDictionary<string, string>; ASettings: TDFRestSettings): TDFRestHttpResult;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  Pair: TPair<string, string>;
  BodyStream: TStringStream;
  Cancel: Boolean;
  MethodStr: string;
  Auth: string;
  I: Integer;
begin
  Result.Init;
  Result.Url := AUrl;
  MethodStr := DFRestHttpMethodToString(AMethod);

  Cancel := False;
  if (ASettings <> nil) and Assigned(ASettings.OnBeforeRequest) then
    ASettings.OnBeforeRequest(ASettings.OwnerComponent, MethodStr, AUrl, Cancel);
  if Cancel then
    raise EDFRestCanceled.Create('Request canceled');

  Client := THTTPClient.Create;
  BodyStream := nil;
  try
    Client.SecureProtocols := [THTTPSecureProtocol.TLS12];
    if ASettings <> nil then
    begin
      Client.ConnectionTimeout := ASettings.ConnectionTimeout;
      Client.ResponseTimeout := ASettings.Timeout;
      if ASettings.UserAgent <> '' then
        Client.UserAgent := ASettings.UserAgent;
    end
    else
    begin
      Client.ConnectionTimeout := 60000;
      Client.ResponseTimeout := 60000;
    end;

    if AHeaders <> nil then
      for Pair in AHeaders do
        Client.CustomHeaders[Pair.Key] := Pair.Value;

    if ASettings <> nil then
    begin
      Auth := ASettings.ResolveAuthorization;
      if Auth <> '' then
      begin
        if (AHeaders = nil) or (not AHeaders.ContainsKey('Authorization')) then
        begin
          if StartsText('Bearer ', Auth) or StartsText('Basic ', Auth) then
            Client.CustomHeaders['Authorization'] := Auth
          else
            Client.CustomHeaders['Authorization'] := 'Bearer ' + Auth;
        end;
      end;
      for Pair in ASettings.DefaultHeaders do
        if (AHeaders = nil) or (not AHeaders.ContainsKey(Pair.Key)) then
          Client.CustomHeaders[Pair.Key] := Pair.Value;
    end;

    try
      case AMethod of
        hmGet:
          Response := Client.Get(AUrl);
        hmHead:
          Response := Client.Head(AUrl);
        hmDelete:
          Response := Client.Delete(AUrl);
        hmPost, hmPut, hmPatch:
          begin
            BodyStream := TStringStream.Create(ABody, TEncoding.UTF8);
            BodyStream.Position := 0;
            if Client.CustomHeaders['Content-Type'] = '' then
              Client.CustomHeaders['Content-Type'] := 'application/json; charset=utf-8';
            case AMethod of
              hmPost:
                Response := Client.Post(AUrl, BodyStream);
              hmPut:
                Response := Client.Put(AUrl, BodyStream);
            else
              Response := Client.Patch(AUrl, BodyStream);
            end;
          end;
      else
        Response := Client.Get(AUrl);
      end;

      Result.StatusCode := Response.StatusCode;
      Result.ReasonPhrase := Response.StatusText;
      Result.Content := Response.ContentAsString;
      for I := 0 to Length(Response.Headers) - 1 do
        Result.Headers.Values[Response.Headers[I].Name] := Response.Headers[I].Value;
    except
      on E: Exception do
      begin
        if (ASettings <> nil) and Assigned(ASettings.OnError) then
          ASettings.OnError(ASettings.OwnerComponent, E);
        raise EDFRestFailed.CreateFmt('HTTP request failed: %s', [E.Message]);
      end;
    end;

    if (ASettings <> nil) and Assigned(ASettings.OnAfterRequest) then
      ASettings.OnAfterRequest(ASettings.OwnerComponent, MethodStr, AUrl,
        Result.StatusCode, Result.Content);
  finally
    BodyStream.Free;
    Client.Free;
  end;
end;

end.
