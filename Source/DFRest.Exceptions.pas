unit DFRest.Exceptions;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  Istisna tipleri                                                             }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils;

type
  EDFRestService = class(Exception);

  EDFRestCanceled = class(EDFRestService);

  EDFRestFailed = class(EDFRestService);

  EDFRestJson = class(EDFRestService);

  EDFRestStatusCode = class(EDFRestService)
  private
    FStatusCode: Integer;
    FResponseBody: string;
    FUrl: string;
  public
    constructor Create(AStatusCode: Integer; const AUrl, AResponseBody, AMessage: string); reintroduce;
    property StatusCode: Integer read FStatusCode;
    property ResponseBody: string read FResponseBody;
    property Url: string read FUrl;
  end;

implementation

{ EDFRestStatusCode }

constructor EDFRestStatusCode.Create(AStatusCode: Integer; const AUrl, AResponseBody,
  AMessage: string);
begin
  inherited Create(AMessage);
  FStatusCode := AStatusCode;
  FUrl := AUrl;
  FResponseBody := AResponseBody;
end;

end.
