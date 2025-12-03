@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\24.0\bin\rsvars.bat"
dcc32 -B EntityDemo.dpr -U"..\..\Sources\Core;..\..\Sources\Entity;..\..\Sources\Specifications;..\..\3thParty\FastMM5"
