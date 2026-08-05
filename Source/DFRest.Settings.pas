unit DFRest.Settings;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  Istek ayarlari                                                              }
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
  DFRest.Types;

type
  TDFRestSettings = class
  private
    FBaseUrl: string;
    FTimeout: Integer;
    FConnectionTimeout: Integer;
    FUserAgent: string;
    FAuthorization: string;
    FGetAuthorization: TDFRestGetAuthorization;
    FDefaultHeaders: TDictionary<string, string>;
    FOnBeforeRequest: TDFRestBeforeRequestEvent;
    FOnAfterRequest: TDFRestAfterRequestEvent;
    FOnError: TDFRestErrorEvent;
    FOwnerComponent: TObject;
  public
    constructor Create;
    destructor Destroy; override;
    function Clone: TDFRestSettings;
    function ResolveAuthorization: string;
    procedure ApplyHeader(const AName, AValue: string);

    property BaseUrl: string read FBaseUrl write FBaseUrl;
    property Timeout: Integer read FTimeout write FTimeout;
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout;
    property UserAgent: string read FUserAgent write FUserAgent;
    property Authorization: string read FAuthorization write FAuthorization;
    property GetAuthorization: TDFRestGetAuthorization read FGetAuthorization write FGetAuthorization;
    property DefaultHeaders: TDictionary<string, string> read FDefaultHeaders;
    property OnBeforeRequest: TDFRestBeforeRequestEvent read FOnBeforeRequest write FOnBeforeRequest;
    property OnAfterRequest: TDFRestAfterRequestEvent read FOnAfterRequest write FOnAfterRequest;
    property OnError: TDFRestErrorEvent read FOnError write FOnError;
    property OwnerComponent: TObject read FOwnerComponent write FOwnerComponent;
  end;

implementation

{ TDFRestSettings }

constructor TDFRestSettings.Create;
begin
  inherited Create;
  FTimeout := 60000;
  FConnectionTimeout := 60000;
  FUserAgent := 'DFRest/1.0';
  FDefaultHeaders := TDictionary<string, string>.Create;
end;

destructor TDFRestSettings.Destroy;
begin
  FDefaultHeaders.Free;
  inherited Destroy;
end;

function TDFRestSettings.Clone: TDFRestSettings;
var
  Pair: TPair<string, string>;
begin
  Result := TDFRestSettings.Create;
  Result.FBaseUrl := FBaseUrl;
  Result.FTimeout := FTimeout;
  Result.FConnectionTimeout := FConnectionTimeout;
  Result.FUserAgent := FUserAgent;
  Result.FAuthorization := FAuthorization;
  Result.FGetAuthorization := FGetAuthorization;
  Result.FOnBeforeRequest := FOnBeforeRequest;
  Result.FOnAfterRequest := FOnAfterRequest;
  Result.FOnError := FOnError;
  Result.FOwnerComponent := FOwnerComponent;
  for Pair in FDefaultHeaders do
    Result.FDefaultHeaders.AddOrSetValue(Pair.Key, Pair.Value);
end;

function TDFRestSettings.ResolveAuthorization: string;
begin
  if Assigned(FGetAuthorization) then
    Result := FGetAuthorization
  else
    Result := FAuthorization;
end;

procedure TDFRestSettings.ApplyHeader(const AName, AValue: string);
begin
  if AName <> '' then
    FDefaultHeaders.AddOrSetValue(AName, AValue);
end;

end.
