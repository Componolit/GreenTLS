with SPARK.Assertions; use SPARK.Assertions;
with SPARK.File_IO; use SPARK.File_IO;

with TLS_Record.TLS_Plaintext;

package body TLS_Record.Tests is

   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("TLS_Record");
   end Name;

   procedure Test_TLS_Plaintext_Client_Hello (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer : Types.Bytes := Read_File ("tests/tls_record_handshake_client_hello.raw");
      Tag    : TLS_Record.Content_Type;
      Length : TLS_Record.Length_Type;
      First  : Types.Index_Type;
      Last   : Types.Index_Type;
   begin
      TLS_Record.TLS_Plaintext.Label (Buffer);
      Assert (TLS_Record.TLS_Plaintext.Valid_Tag (Buffer), "Invalid Tag");
      if TLS_Record.TLS_Plaintext.Valid_Tag (Buffer) then
         Tag := TLS_Record.TLS_Plaintext.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Record.Content_Type'Image (TLS_Record.HANDSHAKE), "Unexpected Tag");
         Assert (TLS_Record.TLS_Plaintext.Valid_Length (Buffer), "Invalid Length");
         if TLS_Record.TLS_Plaintext.Valid_Length (Buffer) then
            Length := TLS_Record.TLS_Plaintext.Get_Length (Buffer);
            Assert (Length'Image, TLS_Record.Length_Type'Image (512), "Unexpected Length");
            Assert (TLS_Record.TLS_Plaintext.Valid_Fragment (Buffer), "Invalid Fragment");
            if TLS_Record.TLS_Plaintext.Valid_Fragment (Buffer) then
               TLS_Record.TLS_Plaintext.Get_Fragment (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (6), "Unexpected Fragment'First");
               Assert (Last'Image, Types.Index_Type'Image (517), "Unexpected Fragment'Last");
            end if;
         end if;
      end if;
      Assert (TLS_Record.TLS_Plaintext.Is_Valid (Buffer), "Invalid Record");
   end Test_TLS_Plaintext_Client_Hello;

   procedure Register_Tests (T : in out Test) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_TLS_Plaintext_Client_Hello'Access, "TLS_Record TLS_Plaintext Client_Hello");
   end Register_Tests;

end TLS_Record.Tests;
