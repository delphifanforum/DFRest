unit DFRest.Proxy;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  TVirtualInterface REST proxy                                                }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  System.Threading,
  System.SyncObjs,
  DFRest.Types,
  DFRest.Attributes,
  DFRest.Settings,
  DFRest.Exceptions,
  DFRest.Http,
  DFRest.Json,
  DFRest.Response;

type
  TDFRestProxy = class(TVirtualInterface)
  private
    FSettings: TDFRestSettings;
    FOwnsSettings: Boolean;
    FIntfTypeInfo: PTypeInfo;
    FLock: TCriticalSection;
    procedure DoInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
    function ResolveBaseUrl(AIntfType: TRttiType): string;
    function FindHttpAttr(Method: TRttiMethod): DFRestHttpMethodAttribute;
    function NormalizeParamName(const AName: string): string;
    function ParamAlias(AParam: TRttiParameter): string;
    function IsBodyParam(AParam: TRttiParameter): Boolean;
    function IsQueryParam(AParam: TRttiParameter; out AName: string): Boolean;
    function IsHeaderParam(AParam: TRttiParameter; out AName: string): Boolean;
    function IsFutureReturn(AReturnType: TRttiType): Boolean;
    function IsApiResponseReturn(AReturnType: TRttiType): Boolean;
    function IsStringType(AType: TRttiType): Boolean;
    function ExecuteMethod(Method: TRttiMethod; const Args: TArray<TValue>;
      AAsResponse: Boolean): TValue;
    function CreateFutureResult(AReturnType: TRttiType; Method: TRttiMethod;
      const Args: TArray<TValue>): TValue;
  public
    constructor Create(AInterfaceTypeInfo: PTypeInfo; ASettings: TDFRestSettings;
      AOwnsSettings: Boolean = True);
    destructor Destroy; override;
  end;

implementation

type
  /// <summary>Delegates ITask/IFuture methods to an inner task + stored TValue.</summary>
  TDFRestFutureBridge = class(TVirtualInterface)
  private
    FTask: ITask;
    FValue: TValue;
    FError: Exception;
    FOwnsError: Boolean;
    FDone: Boolean;
    FLock: TCriticalSection;
    procedure EnsureDone;
    procedure BridgeInvoke(Method: TRttiMethod; const Args: TArray<TValue>; out Result: TValue);
  public
    constructor Create(AFutureTypeInfo: PTypeInfo);
    destructor Destroy; override;
    procedure AttachTask(const ATask: ITask);
    procedure SetValue(const AValue: TValue);
    procedure SetError(AError: Exception);
  end;

{ TDFRestFutureBridge }

constructor TDFRestFutureBridge.Create(AFutureTypeInfo: PTypeInfo);
begin
  FLock := TCriticalSection.Create;
  FDone := False;
  FOwnsError := False;
  inherited Create(AFutureTypeInfo, BridgeInvoke);
end;

procedure TDFRestFutureBridge.AttachTask(const ATask: ITask);
begin
  FTask := ATask;
end;

destructor TDFRestFutureBridge.Destroy;
begin
  if FOwnsError then
    FError.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TDFRestFutureBridge.SetValue(const AValue: TValue);
begin
  FLock.Enter;
  try
    FValue := AValue;
    FDone := True;
  finally
    FLock.Leave;
  end;
end;

procedure TDFRestFutureBridge.SetError(AError: Exception);
begin
  FLock.Enter;
  try
    FError := AError;
    FOwnsError := True;
    FDone := True;
  finally
    FLock.Leave;
  end;
end;

procedure TDFRestFutureBridge.EnsureDone;
var
  E: Exception;
begin
  if FTask <> nil then
    FTask.Wait;
  FLock.Enter;
  try
    if FError <> nil then
    begin
      E := FError;
      FError := nil;
      FOwnsError := False;
      raise E;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TDFRestFutureBridge.BridgeInvoke(Method: TRttiMethod; const Args: TArray<TValue>;
  out Result: TValue);
var
  Name: string;
begin
  Name := Method.Name;
  if SameText(Name, 'GetValue') or SameText(Name, 'Get_Value') then
  begin
    EnsureDone;
    Result := FValue;
  end
  else if SameText(Name, 'Wait') then
  begin
    if Length(Args) <= 1 then
    begin
      if FTask <> nil then
        FTask.Wait;
      Result := TValue.From<Boolean>(True);
    end
    else
    begin
      if FTask <> nil then
        Result := TValue.From<Boolean>(FTask.Wait(Cardinal(Args[1].AsInteger)))
      else
        Result := TValue.From<Boolean>(True);
    end;
  end
  else if SameText(Name, 'Cancel') then
  begin
    if FTask <> nil then
      FTask.Cancel;
  end
  else if SameText(Name, 'Start') then
  begin
    if FTask <> nil then
      Result := TValue.From<ITask>(FTask.Start)
    else
      Result := TValue.From<ITask>(ITask(nil));
  end
  else if SameText(Name, 'GetStatus') or SameText(Name, 'Get_Status') then
  begin
    if FTask <> nil then
      Result := TValue.From<TTaskStatus>(FTask.Status)
    else
      Result := TValue.From<TTaskStatus>(TTaskStatus.Completed);
  end
  else if SameText(Name, 'GetId') or SameText(Name, 'Get_Id') then
  begin
    if FTask <> nil then
      Result := TValue.From<Integer>(Integer(FTask.Id))
    else
      Result := TValue.From<Integer>(0);
  end
  else if SameText(Name, 'GetException') or SameText(Name, 'Get_Exception') or
    SameText(Name, 'Get_FatalException') or SameText(Name, 'GetFatalException') then
  begin
    EnsureDone;
    Result := TValue.From<Exception>(FError);
  end
  else if SameText(Name, 'QueryInterface') then
  begin
    // Let TVirtualInterface default handle if possible — fall through empty
  end;
end;

{ TDFRestProxy }

constructor TDFRestProxy.Create(AInterfaceTypeInfo: PTypeInfo; ASettings: TDFRestSettings;
  AOwnsSettings: Boolean);
begin
  if AInterfaceTypeInfo = nil then
    raise EDFRestService.Create('Interface type is required');
  FIntfTypeInfo := AInterfaceTypeInfo;
  FSettings := ASettings;
  FOwnsSettings := AOwnsSettings;
  FLock := TCriticalSection.Create;
  inherited Create(AInterfaceTypeInfo, DoInvoke);
end;

destructor TDFRestProxy.Destroy;
begin
  if FOwnsSettings then
    FSettings.Free;
  FLock.Free;
  inherited Destroy;
end;

function TDFRestProxy.NormalizeParamName(const AName: string): string;
begin
  Result := AName;
  if (Length(Result) > 1) and ((Result[1] = 'A') or (Result[1] = 'a')) then
  begin
    if (Length(Result) > 1) and (Result[2] = UpCase(Result[2])) then
      Delete(Result, 1, 1);
  end;
end;

function TDFRestProxy.ParamAlias(AParam: TRttiParameter): string;
var
  Attr: TCustomAttribute;
begin
  Result := '';
  for Attr in AParam.GetAttributes do
    if Attr is DFRestAliasAsAttribute then
      Exit(DFRestAliasAsAttribute(Attr).Name);
  Result := NormalizeParamName(AParam.Name);
end;

function TDFRestProxy.IsBodyParam(AParam: TRttiParameter): Boolean;
var
  Attr: TCustomAttribute;
  N: string;
begin
  for Attr in AParam.GetAttributes do
    if Attr is DFRestBodyAttribute then
      Exit(True);
  N := NormalizeParamName(AParam.Name);
  Result := SameText(N, 'Body') or SameText(N, 'BodyContent') or SameText(N, 'Content');
end;

function TDFRestProxy.IsQueryParam(AParam: TRttiParameter; out AName: string): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result := False;
  AName := '';
  for Attr in AParam.GetAttributes do
    if Attr is DFRestQueryAttribute then
    begin
      AName := DFRestQueryAttribute(Attr).Name;
      if AName = '' then
        AName := ParamAlias(AParam);
      Exit(True);
    end;
end;

function TDFRestProxy.IsHeaderParam(AParam: TRttiParameter; out AName: string): Boolean;
var
  Attr: TCustomAttribute;
begin
  Result := False;
  AName := '';
  for Attr in AParam.GetAttributes do
    if Attr is DFRestHeaderAttribute then
    begin
      AName := DFRestHeaderAttribute(Attr).Name;
      Exit(True);
    end;
end;

function TDFRestProxy.IsStringType(AType: TRttiType): Boolean;
begin
  Result := (AType <> nil) and (AType.TypeKind in [tkUString, tkString, tkWString, tkLString]);
end;

function TDFRestProxy.IsFutureReturn(AReturnType: TRttiType): Boolean;
var
  N: string;
begin
  Result := False;
  if AReturnType = nil then
    Exit;
  N := AReturnType.Name;
  Result := (Pos('IFuture<', N) > 0) or (Pos('IFuture$', N) > 0) or
    SameText(N, 'IFuture');
end;

function TDFRestProxy.IsApiResponseReturn(AReturnType: TRttiType): Boolean;
var
  N: string;
begin
  Result := False;
  if AReturnType = nil then
    Exit;
  N := AReturnType.Name;
  Result := (Pos('IDFRestResponse', N) > 0);
end;

function TDFRestProxy.ResolveBaseUrl(AIntfType: TRttiType): string;
var
  Attr: TCustomAttribute;
begin
  Result := '';
  if FSettings <> nil then
    Result := FSettings.BaseUrl;
  if AIntfType <> nil then
    for Attr in AIntfType.GetAttributes do
      if Attr is DFRestBaseUrlAttribute then
      begin
        if Result = '' then
          Result := DFRestBaseUrlAttribute(Attr).BaseUrl;
        Break;
      end;
end;

function TDFRestProxy.FindHttpAttr(Method: TRttiMethod): DFRestHttpMethodAttribute;
var
  Attr: TCustomAttribute;
begin
  Result := nil;
  for Attr in Method.GetAttributes do
    if Attr is DFRestHttpMethodAttribute then
      Exit(DFRestHttpMethodAttribute(Attr));
end;

function TDFRestProxy.ExecuteMethod(Method: TRttiMethod; const Args: TArray<TValue>;
  AAsResponse: Boolean): TValue;
var
  Ctx: TRttiContext;
  IntfType: TRttiType;
  HttpAttr: DFRestHttpMethodAttribute;
  PathTokens, QueryParams, Headers: TDictionary<string, string>;
  Params: TArray<TRttiParameter>;
  I: Integer;
  ArgIndex: Integer;
  Param: TRttiParameter;
  Alias, HName, QName: string;
  BodyJson: string;
  HasBody: Boolean;
  Path, Url, BaseUrl: string;
  Attr: TCustomAttribute;
  HttpResult: TDFRestHttpResult;
  RetType: TRttiType;
  Obj: TObject;
  RespObj: TDFRestResponse;
  Success: Boolean;
begin
  Ctx := TRttiContext.Create;
  PathTokens := TDictionary<string, string>.Create;
  QueryParams := TDictionary<string, string>.Create;
  Headers := TDictionary<string, string>.Create;
  BodyJson := '';
  HasBody := False;
  try
    IntfType := Ctx.GetType(FIntfTypeInfo);
    HttpAttr := FindHttpAttr(Method);
    if HttpAttr = nil then
      raise EDFRestService.CreateFmt('Method %s has no HTTP attribute (DFRestGet/Post/...)',
        [Method.Name]);

    BaseUrl := ResolveBaseUrl(IntfType);
    Path := HttpAttr.Path;

    // Interface-level headers
    if IntfType <> nil then
      for Attr in IntfType.GetAttributes do
        if Attr is DFRestHeadersAttribute then
          Headers.AddOrSetValue(DFRestHeadersAttribute(Attr).Name,
            DFRestHeadersAttribute(Attr).Value);

    // Method-level headers
    for Attr in Method.GetAttributes do
      if Attr is DFRestHeadersAttribute then
        Headers.AddOrSetValue(DFRestHeadersAttribute(Attr).Name,
          DFRestHeadersAttribute(Attr).Value);

    // Args[0] = Self (interface). Parameters start at 1.
    Params := Method.GetParameters;
    ArgIndex := 1;
    for I := 0 to High(Params) do
    begin
      Param := Params[I];
      if ArgIndex > High(Args) then
        Break;

      if IsBodyParam(Param) then
      begin
        BodyJson := TDFRestJson.ValueToJson(Args[ArgIndex]);
        HasBody := True;
      end
      else if IsHeaderParam(Param, HName) then
        Headers.AddOrSetValue(HName, Args[ArgIndex].ToString)
      else if IsQueryParam(Param, QName) then
        QueryParams.AddOrSetValue(QName, Args[ArgIndex].ToString)
      else
      begin
        Alias := ParamAlias(Param);
        if (Pos('{' + Alias + '}', Path) > 0) or
          (Pos('{' + Param.Name + '}', Path) > 0) or
          (Pos('{' + NormalizeParamName(Param.Name) + '}', Path) > 0) then
        begin
          PathTokens.AddOrSetValue(Alias, Args[ArgIndex].ToString);
          PathTokens.AddOrSetValue(Param.Name, Args[ArgIndex].ToString);
          PathTokens.AddOrSetValue(NormalizeParamName(Param.Name), Args[ArgIndex].ToString);
        end
        else
          QueryParams.AddOrSetValue(Alias, Args[ArgIndex].ToString);
      end;
      Inc(ArgIndex);
    end;

    Path := TDFRestHttp.ReplacePathTokens(Path, PathTokens);
    Path := TDFRestHttp.AppendQuery(Path, QueryParams);
    Url := TDFRestHttp.JoinUrl(BaseUrl, Path);

    if not HasBody then
      BodyJson := '';

    HttpResult := TDFRestHttp.Execute(HttpAttr.Method, Url, BodyJson, Headers, FSettings);
    try
      Success := (HttpResult.StatusCode >= 200) and (HttpResult.StatusCode <= 299);
      RetType := Method.ReturnType;

      if AAsResponse or IsApiResponseReturn(RetType) then
      begin
        RespObj := TDFRestResponse.Create;
        RespObj.SetResult(HttpResult.StatusCode, HttpResult.ReasonPhrase, Url, HttpResult.Content);
        if HttpResult.Headers <> nil then
          RespObj.HeaderList.Assign(HttpResult.Headers);
        if Success and (RetType <> nil) and (not IsStringType(RetType)) then
        begin
          // For IDFRestResponse<T>, try to deserialize T if class — stored as ContentObject
          // Element type extraction is best-effort; deserialize when JSON object present
          if (Trim(HttpResult.Content) <> '') and (HttpResult.Content[1] = '{') then
          begin
            // Leave Content as string; ContentObject optional
          end;
        end;
        if not Success then
          RespObj.SetError(
            EDFRestStatusCode.Create(HttpResult.StatusCode, Url, HttpResult.Content,
              Format('HTTP %d %s', [HttpResult.StatusCode, HttpResult.ReasonPhrase])),
            True);
        Result := TValue.From<IDFRestResponse>(RespObj);
        Exit;
      end;

      if not Success then
        raise EDFRestStatusCode.Create(HttpResult.StatusCode, Url, HttpResult.Content,
          Format('HTTP %d %s for %s', [HttpResult.StatusCode, HttpResult.ReasonPhrase, Url]));

      if RetType = nil then
      begin
        Result := TValue.Empty;
        Exit;
      end;

      if IsStringType(RetType) then
        Result := TValue.From<string>(HttpResult.Content)
      else if RetType.TypeKind = tkClass then
      begin
        Obj := TDFRestJson.JsonToObject(RetType.Handle, HttpResult.Content);
        if Obj = nil then
          Result := TValue.Empty
        else
          Result := TValue.From<TObject>(Obj).Cast(RetType.Handle);
      end
      else
        Result := TDFRestJson.JsonToValue(RetType.Handle, HttpResult.Content);
    finally
      HttpResult.FreeHeaders;
    end;
  finally
    PathTokens.Free;
    QueryParams.Free;
    Headers.Free;
    Ctx.Free;
  end;
end;

function TDFRestProxy.CreateFutureResult(AReturnType: TRttiType; Method: TRttiMethod;
  const Args: TArray<TValue>): TValue;
var
  Bridge: TDFRestFutureBridge;
  CapturedMethod: TRttiMethod;
  CapturedArgs: TArray<TValue>;
  Task: ITask;
  AsResponse: Boolean;
  Intf: IInterface;
begin
  CapturedMethod := Method;
  CapturedArgs := Copy(Args);
  AsResponse := Pos('IDFRestResponse', AReturnType.Name) > 0;

  Bridge := TDFRestFutureBridge.Create(AReturnType.Handle);
  Task := TTask.Run(
    procedure
    var
      V: TValue;
    begin
      try
        V := ExecuteMethod(CapturedMethod, CapturedArgs, AsResponse);
        Bridge.SetValue(V);
      except
        on E: Exception do
          Bridge.SetError(Exception(E.ClassType).Create(E.Message));
      end;
    end);
  Bridge.AttachTask(Task);
  Intf := Bridge;
  TValue.Make(@Intf, AReturnType.Handle, Result);
end;

procedure TDFRestProxy.DoInvoke(Method: TRttiMethod; const Args: TArray<TValue>;
  out Result: TValue);
var
  RetType: TRttiType;
begin
  // Skip IInterface methods
  if (Method.Parent <> nil) and (Method.Parent.Handle = TypeInfo(IInterface)) then
    Exit;
  if SameText(Method.Name, 'QueryInterface') or SameText(Method.Name, 'AddRef') or
    SameText(Method.Name, 'Release') or SameText(Method.Name, '_AddRef') or
    SameText(Method.Name, '_Release') then
    Exit;

  FLock.Enter;
  try
    RetType := Method.ReturnType;
    if IsFutureReturn(RetType) then
      Result := CreateFutureResult(RetType, Method, Args)
    else if IsApiResponseReturn(RetType) then
      Result := ExecuteMethod(Method, Args, True)
    else
      Result := ExecuteMethod(Method, Args, False);
  finally
    FLock.Leave;
  end;
end;

end.
