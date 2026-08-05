unit DFRest.Json;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  JSON serialize / deserialize (REST.Json, class DTO)                         }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  System.JSON,
  REST.Json,
  DFRest.Exceptions;

type
  TDFRestJson = class
  public
    class function ObjectToJson(AObject: TObject): string; static;
    class function ValueToJson(const AValue: TValue): string; static;
    class function JsonToObject(ATypeInfo: PTypeInfo; const AJson: string): TObject; static;
    class function JsonToValue(ATypeInfo: PTypeInfo; const AJson: string): TValue; static;
  end;

implementation

{ TDFRestJson }

class function TDFRestJson.ObjectToJson(AObject: TObject): string;
begin
  if AObject = nil then
    Exit('null');
  Result := TJson.ObjectToJsonString(AObject);
end;

class function TDFRestJson.ValueToJson(const AValue: TValue): string;
begin
  if AValue.IsEmpty then
    Exit('null');
  if AValue.IsObject then
    Exit(ObjectToJson(AValue.AsObject));
  if AValue.Kind in [tkUString, tkString, tkWString, tkLString] then
    Exit(AValue.AsString);
  if AValue.Kind in [tkInteger, tkInt64] then
    Exit(IntToStr(AValue.AsInt64));
  if AValue.Kind = tkFloat then
    Exit(FloatToStr(AValue.AsExtended, TFormatSettings.Invariant));
  if AValue.Kind = tkEnumeration then
  begin
    if AValue.TypeInfo = TypeInfo(Boolean) then
    begin
      if AValue.AsBoolean then
        Exit('true')
      else
        Exit('false');
    end;
  end;
  Result := AValue.ToString;
end;

class function TDFRestJson.JsonToObject(ATypeInfo: PTypeInfo; const AJson: string): TObject;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Inst: TRttiInstanceType;
  Obj: TObject;
  JsonValue: TJSONValue;
  JsonObj: TJSONObject;
begin
  if (ATypeInfo = nil) or (ATypeInfo.Kind <> tkClass) then
    raise EDFRestJson.Create('JSON deserialization requires a class type');
  if Trim(AJson) = '' then
    Exit(nil);

  JsonValue := TJSONObject.ParseJSONValue(AJson);
  if JsonValue = nil then
    raise EDFRestJson.Create('Invalid JSON');
  try
    if not (JsonValue is TJSONObject) then
      raise EDFRestJson.Create('JSON root must be an object for class DTO');
    JsonObj := TJSONObject(JsonValue);

    Ctx := TRttiContext.Create;
    try
      RttiType := Ctx.GetType(ATypeInfo);
      if not (RttiType is TRttiInstanceType) then
        raise EDFRestJson.CreateFmt('Type %s is not a class', [string(ATypeInfo.Name)]);
      Inst := TRttiInstanceType(RttiType);
      Obj := Inst.MetaclassType.Create;
      try
        TJson.JsonToObject(Obj, JsonObj);
        Result := Obj;
      except
        on E: Exception do
        begin
          Obj.Free;
          raise EDFRestJson.CreateFmt('JSON deserialize failed: %s', [E.Message]);
        end;
      end;
    finally
      Ctx.Free;
    end;
  finally
    JsonValue.Free;
  end;
end;

class function TDFRestJson.JsonToValue(ATypeInfo: PTypeInfo; const AJson: string): TValue;
var
  Obj: TObject;
  Trimmed: string;
begin
  if ATypeInfo = nil then
  begin
    Result := TValue.Empty;
    Exit;
  end;

  Trimmed := Trim(AJson);
  case ATypeInfo.Kind of
    tkUString, tkString, tkWString, tkLString:
      Result := TValue.From<string>(AJson);
    tkClass:
      begin
        Obj := JsonToObject(ATypeInfo, AJson);
        if Obj = nil then
          Result := TValue.Empty
        else
          Result := TValue.From<TObject>(Obj).Cast(ATypeInfo);
      end;
    tkInteger:
      Result := TValue.From<Integer>(StrToIntDef(Trimmed, 0));
    tkInt64:
      Result := TValue.From<Int64>(StrToInt64Def(Trimmed, 0));
    tkFloat:
      Result := TValue.From<Double>(StrToFloatDef(Trimmed, 0, TFormatSettings.Invariant));
    tkEnumeration:
      if ATypeInfo = TypeInfo(Boolean) then
        Result := TValue.From<Boolean>(SameText(Trimmed, 'true') or (Trimmed = '1'))
      else
        Result := TValue.Empty;
  else
    Result := TValue.From<string>(AJson);
  end;
end;

end.
