unit DFRest.Response;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  ApiResponse modeli                                                          }
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
  System.TypInfo;

type
  IDFRestResponse = interface
    ['{8F2C1A90-4B6E-4D3A-9C71-1E5D8A0B2F44}']
    function GetStatusCode: Integer;
    function GetReasonPhrase: string;
    function GetContent: string;
    function GetIsSuccessStatusCode: Boolean;
    function GetError: Exception;
    function GetUrl: string;
    function GetContentAsObject: TObject;
    function GetHeaders: TStrings;
    property StatusCode: Integer read GetStatusCode;
    property ReasonPhrase: string read GetReasonPhrase;
    property Content: string read GetContent;
    property IsSuccessStatusCode: Boolean read GetIsSuccessStatusCode;
    property Error: Exception read GetError;
    property Url: string read GetUrl;
    property ContentAsObject: TObject read GetContentAsObject;
    property Headers: TStrings read GetHeaders;
  end;

  IDFRestResponse<T> = interface(IDFRestResponse)
    function GetContentValue: T;
    property ContentValue: T read GetContentValue;
  end;

  TDFRestResponse = class(TInterfacedObject, IDFRestResponse)
  private
    FStatusCode: Integer;
    FReasonPhrase: string;
    FContent: string;
    FUrl: string;
    FError: Exception;
    FOwnsError: Boolean;
    FContentObject: TObject;
    FOwnsContentObject: Boolean;
    FHeaders: TStringList;
  protected
    function GetStatusCode: Integer;
    function GetReasonPhrase: string;
    function GetContent: string;
    function GetIsSuccessStatusCode: Boolean;
    function GetError: Exception;
    function GetUrl: string;
    function GetContentAsObject: TObject;
    function GetHeaders: TStrings;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetResult(AStatusCode: Integer; const AReason, AUrl, AContent: string);
    procedure SetContentObject(AObject: TObject; AOwns: Boolean);
    procedure SetError(AError: Exception; AOwns: Boolean);
    property StatusCode: Integer read FStatusCode write FStatusCode;
    property ReasonPhrase: string read FReasonPhrase write FReasonPhrase;
    property Content: string read FContent write FContent;
    property Url: string read FUrl write FUrl;
    property ContentObject: TObject read FContentObject;
    property HeaderList: TStringList read FHeaders;
  end;

  TDFRestResponse<T> = class(TDFRestResponse, IDFRestResponse<T>)
  private
    FContentValue: T;
  protected
    function GetContentValue: T;
  public
    procedure SetContentValue(const AValue: T);
    property ContentValue: T read FContentValue;
  end;

  /// <summary>Non-generic factory helpers used by the proxy.</summary>
  TDFRestResponseFactory = class
  public
    class function CreateRaw: IDFRestResponse; static;
    class function WrapObject(AStatusCode: Integer; const AReason, AUrl, AContent: string;
      AObject: TObject; AOwnsObject: Boolean): IDFRestResponse; static;
  end;

implementation

{ TDFRestResponse }

constructor TDFRestResponse.Create;
begin
  inherited Create;
  FHeaders := TStringList.Create;
end;

destructor TDFRestResponse.Destroy;
begin
  if FOwnsContentObject then
    FContentObject.Free;
  if FOwnsError then
    FError.Free;
  FHeaders.Free;
  inherited Destroy;
end;

function TDFRestResponse.GetStatusCode: Integer;
begin
  Result := FStatusCode;
end;

function TDFRestResponse.GetReasonPhrase: string;
begin
  Result := FReasonPhrase;
end;

function TDFRestResponse.GetContent: string;
begin
  Result := FContent;
end;

function TDFRestResponse.GetIsSuccessStatusCode: Boolean;
begin
  Result := (FStatusCode >= 200) and (FStatusCode <= 299);
end;

function TDFRestResponse.GetError: Exception;
begin
  Result := FError;
end;

function TDFRestResponse.GetUrl: string;
begin
  Result := FUrl;
end;

function TDFRestResponse.GetContentAsObject: TObject;
begin
  Result := FContentObject;
end;

function TDFRestResponse.GetHeaders: TStrings;
begin
  Result := FHeaders;
end;

procedure TDFRestResponse.SetResult(AStatusCode: Integer; const AReason, AUrl, AContent: string);
begin
  FStatusCode := AStatusCode;
  FReasonPhrase := AReason;
  FUrl := AUrl;
  FContent := AContent;
end;

procedure TDFRestResponse.SetContentObject(AObject: TObject; AOwns: Boolean);
begin
  if FOwnsContentObject then
    FContentObject.Free;
  FContentObject := AObject;
  FOwnsContentObject := AOwns;
end;

procedure TDFRestResponse.SetError(AError: Exception; AOwns: Boolean);
begin
  if FOwnsError then
    FError.Free;
  FError := AError;
  FOwnsError := AOwns;
end;

{ TDFRestResponse<T> }

function TDFRestResponse<T>.GetContentValue: T;
begin
  Result := FContentValue;
end;

procedure TDFRestResponse<T>.SetContentValue(const AValue: T);
begin
  FContentValue := AValue;
end;

{ TDFRestResponseFactory }

class function TDFRestResponseFactory.CreateRaw: IDFRestResponse;
begin
  Result := TDFRestResponse.Create;
end;

class function TDFRestResponseFactory.WrapObject(AStatusCode: Integer; const AReason, AUrl,
  AContent: string; AObject: TObject; AOwnsObject: Boolean): IDFRestResponse;
var
  Resp: TDFRestResponse;
begin
  Resp := TDFRestResponse.Create;
  Resp.SetResult(AStatusCode, AReason, AUrl, AContent);
  Resp.SetContentObject(AObject, AOwnsObject);
  Result := Resp;
end;

end.
