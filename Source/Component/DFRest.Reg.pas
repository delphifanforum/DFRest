unit DFRest.Reg;

{******************************************************************************}
{  DFRest 1.0.0                                                                }
{  Design-time kayit                                                           }
{                                                                              }
{  Author : Alen Ibric (Delphifan)                                             }
{  E-mail : adsdelphi@gmail.com                                                }
{  Web    : https://www.delphifan.com                                          }
{******************************************************************************}

interface

procedure Register;

implementation

uses
  System.Classes,
  DFRest.Component;

procedure Register;
begin
  RegisterComponents('DFRest', [TDFRestClient]);
end;

end.
