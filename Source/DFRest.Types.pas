unit DFRest.Types;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  Ortak tipler                                                                }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

uses
  System.SysUtils;

type
  TDFRestHttpMethod = (hmGet, hmPost, hmPut, hmDelete, hmPatch, hmHead);

  TDFRestParamKind = (pkPath, pkQuery, pkBody, pkHeader);

  TDFRestGetAuthorization = reference to function: string;

  TDFRestGetAuthorizationEvent = procedure(Sender: TObject; var AToken: string) of object;

  TDFRestBeforeRequestEvent = procedure(Sender: TObject; const AMethod, AUrl: string;
    var ACancel: Boolean) of object;
  TDFRestAfterRequestEvent = procedure(Sender: TObject; const AMethod, AUrl: string;
    AStatusCode: Integer; const AResponseBody: string) of object;
  TDFRestErrorEvent = procedure(Sender: TObject; E: Exception) of object;

function DFRestHttpMethodToString(AMethod: TDFRestHttpMethod): string;

implementation

function DFRestHttpMethodToString(AMethod: TDFRestHttpMethod): string;
begin
  case AMethod of
    hmGet: Result := 'GET';
    hmPost: Result := 'POST';
    hmPut: Result := 'PUT';
    hmDelete: Result := 'DELETE';
    hmPatch: Result := 'PATCH';
    hmHead: Result := 'HEAD';
  else
    Result := 'GET';
  end;
end;

end.
