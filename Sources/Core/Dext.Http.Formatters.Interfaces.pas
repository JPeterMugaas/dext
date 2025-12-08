unit Dext.Http.Formatters.Interfaces;

interface

uses
  System.Rtti,
  Dext.Http.Interfaces;

type
  IOutputFormatterContext = interface
    ['{AA11BB22-CC33-44DD-EE55-FF6677889900}']
    function GetHttpContext: IHttpContext;
    function GetObjectType: TRttiType;
    function GetObject: TValue;
    
    property HttpContext: IHttpContext read GetHttpContext;
    property ObjectType: TRttiType read GetObjectType;
    property &Object: TValue read GetObject;
  end;

  IOutputFormatter = interface
    ['{BB22CC33-DD44-55EE-FF66-77889900AA11}']
    /// <summary>
    ///   Determines if this formatter can write the result for the given context (Content-Type, Object Type).
    /// </summary>
    function CanWriteResult(const Context: IOutputFormatterContext): Boolean;

    /// <summary>
    ///   Returns the list of media types supported by this formatter (e.g. 'application/json').
    /// </summary>
    function GetSupportedMediaTypes: TArray<string>;
    
    /// <summary>
    ///   Writes the object to the response body.
    /// </summary>
    procedure Write(const Context: IOutputFormatterContext);
  end;

  /// <summary>
  ///   Service responsible for selecting the best formatter based on Accept header.
  /// </summary>
  IOutputFormatterSelector = interface
    ['{CC33DD44-EE55-66FF-7700-8899AABBCC22}']
    function SelectFormatter(const Context: IOutputFormatterContext; const Formatters: TArray<IOutputFormatter>): IOutputFormatter;
  end;

  IOutputFormatterRegistry = interface
    ['{DD44EE55-FF66-7700-8811-99AABBCCDDEE}']
    procedure Add(Formatter: IOutputFormatter);
    function GetAll: TArray<IOutputFormatter>;
  end;

implementation

end.
