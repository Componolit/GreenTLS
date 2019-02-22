with TLS_Record.Tests;
with TLS_Handshake.Tests;

package body Test_Suite is

   function Suite return Access_Test_Suite is
      Result : constant Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
   begin
      Result.Add_Test (new TLS_Record.Tests.Test);
      Result.Add_Test (new TLS_Handshake.Tests.Test);
      return Result;
   end Suite;

end Test_Suite;
