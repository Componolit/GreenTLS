with SPARK.Assertions; use SPARK.Assertions;
with SPARK.File_IO; use SPARK.File_IO;

with TLS_Handshake.Handshake;
with TLS_Handshake.Contains;
with TLS_Handshake.Client_Hello;
with TLS_Handshake.Server_Hello;
with TLS_Handshake.Encrypted_Extensions;
with TLS_Handshake.Certificate;
with TLS_Handshake.Certificate_Verify;
with TLS_Handshake.Finished;
with TLS_Handshake.New_Session_Ticket;
with TLS_Handshake.Extensions;
with TLS_Handshake.Extension;

package body TLS_Handshake.Tests is

   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("TLS_Handshake");
   end Name;

   procedure Test_TLS_Handshake_Client_Hello (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer : Types.Bytes := Read_File ("tests/tls_handshake_client_hello.raw");
      Valid  : Boolean;
      Tag    : TLS_Handshake.Handshake_Type;
      Length : TLS_Handshake.Length_Type;
      First  : Types.Index_Type;
      Last   : Types.Index_Type;
   begin
      TLS_Handshake.Handshake.Label (Buffer);
      Valid := TLS_Handshake.Handshake.Valid_Tag (Buffer);
      Assert (Valid, "Invalid Tag");
      if Valid then
         Tag := TLS_Handshake.Handshake.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Handshake.Handshake_Type'Image (TLS_Handshake.HANDSHAKE_CLIENT_HELLO), "Unexpected Tag");
         Valid := TLS_Handshake.Handshake.Valid_Length (Buffer);
         Assert (Valid, "Invalid Length");
         if Valid then
            Length := TLS_Handshake.Handshake.Get_Length (Buffer);
            Assert (Length'Image, TLS_Handshake.Length_Type'Image (508), "Unexpected Length");
            Valid := TLS_Handshake.Handshake.Valid_Payload (Buffer);
            Assert (Valid, "Invalid Payload");
            if Valid then
               TLS_Handshake.Handshake.Get_Payload (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (5), "Unexpected Payload'First");
               Assert (Last'Image, Types.Index_Type'Image (512), "Unexpected Payload'Last");
               Valid := TLS_Handshake.Contains.Client_Hello_Handshake (Buffer);
               Assert (Valid, "Handshake message contains no Client Hello");
               if Valid then
                  Valid := TLS_Handshake.Client_Hello.Is_Valid (Buffer (First .. Last));
                  Assert (Valid, "Invalid Client Hello");
               end if;
            end if;
         end if;
      end if;
      Assert (TLS_Handshake.Handshake.Is_Valid (Buffer), "Invalid Handshake");
   end Test_TLS_Handshake_Client_Hello;

   procedure Test_TLS_Handshake_Server_Hello (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer                    : Types.Bytes := Read_File ("tests/tls_handshake_server_hello.raw");
      Valid                     : Boolean;
      Tag                       : TLS_Handshake.Handshake_Type;
      Length                    : TLS_Handshake.Length_Type;
      First                     : Types.Index_Type;
      Last                      : Types.Index_Type;
      Random_First              : Types.Index_Type;
      Random_Last               : Types.Index_Type;
      Legacy_Session_ID_First   : Types.Index_Type;
      Legacy_Session_ID_Last    : Types.Index_Type;
      Cipher_Suite              : TLS_Handshake.Cipher_Suite_Type;
      Legacy_Compression_Method : TLS_Handshake.Legacy_Compression_Method_Type;
      Extensions_First          : Types.Index_Type;
      Extensions_Last           : Types.Index_Type;
      Offset                    : TLS_Handshake.Extensions.Offset_Type;
      Extension_First           : Types.Index_Type;
      Extension_Last            : Types.Index_Type;
      Extension_Tag             : TLS_Handshake.Extension_Type;
   begin
      TLS_Handshake.Handshake.Label (Buffer);
      Valid := TLS_Handshake.Handshake.Valid_Tag (Buffer);
      Assert (Valid, "Invalid Tag");
      if Valid then
         Tag := TLS_Handshake.Handshake.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Handshake.Handshake_Type'Image (TLS_Handshake.HANDSHAKE_SERVER_HELLO), "Unexpected Tag");
         Valid := TLS_Handshake.Handshake.Valid_Length (Buffer);
         Assert (Valid, "Invalid Length");
         if Valid then
            Length := TLS_Handshake.Handshake.Get_Length (Buffer);
            Assert (Length'Image, TLS_Handshake.Length_Type'Image (86), "Unexpected Length");
            Valid := TLS_Handshake.Handshake.Valid_Payload (Buffer);
            Assert (Valid, "Invalid Payload");
            if Valid then
               TLS_Handshake.Handshake.Get_Payload (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (5), "Unexpected Payload'First");
               Assert (Last'Image, Types.Index_Type'Image (90), "Unexpected Payload'Last");
               Valid := TLS_Handshake.Contains.Server_Hello_Handshake (Buffer);
               Assert (Valid, "Handshake message contains no Server Hello");
               if Valid then
                  Valid := TLS_Handshake.Server_Hello.Valid_Random (Buffer (First .. Last));
                  Assert (Valid, "Invalid Random");
                  if Valid then
                     TLS_Handshake.Server_Hello.Get_Random (Buffer (First .. Last), Random_First, Random_Last);
                     Assert (Random_First'Image, Types.Index_Type'Image (7), "Unexpected Random'First");
                     Assert (Random_Last'Image, Types.Index_Type'Image (38), "Unexpected Random'Last");
                     Valid := TLS_Handshake.Server_Hello.Valid_Legacy_Session_ID (Buffer (First .. Last));
                     Assert (Valid, "Invalid Legacy Session ID");
                     if Valid then
                        TLS_Handshake.Server_Hello.Get_Legacy_Session_ID (Buffer (First .. Last), Legacy_Session_ID_First, Legacy_Session_ID_Last);
                        Assert (Legacy_Session_ID_First'Image, Types.Index_Type'Image (40), "Unexpected Legacy_Session_ID'First");
                        Assert (Legacy_Session_ID_Last'Image, Types.Index_Type'Image (39), "Unexpected Legacy_Session_ID'Last");
                        Valid := TLS_Handshake.Server_Hello.Valid_Cipher_Suite (Buffer (First .. Last));
                        Assert (Valid, "Invalid Cipher Suite");
                        if Valid then
                           Cipher_Suite := TLS_Handshake.Server_Hello.Get_Cipher_Suite (Buffer (First .. Last));
                           Assert (Cipher_Suite'Image, TLS_Handshake.Cipher_Suite_Type'Image (4865), "Unexpected Cipher Suite");
                           Valid := TLS_Handshake.Server_Hello.Valid_Legacy_Compression_Method (Buffer (First .. Last));
                           Assert (Valid, "Invalid Legacy Compression Method");
                           if Valid then
                              Legacy_Compression_Method := TLS_Handshake.Server_Hello.Get_Legacy_Compression_Method (Buffer (First .. Last));
                              Assert (Legacy_Compression_Method'Image, TLS_Handshake.Legacy_Compression_Method_Type'Image (0), "Unexpected Legacy Compression Method");
                              Valid := TLS_Handshake.Server_Hello.Valid_Extensions (Buffer (First .. Last));
                              Assert (Valid, "Invalid Extensions");
                              if Valid then
                                 TLS_Handshake.Server_Hello.Get_Extensions (Buffer (First .. Last), Extensions_First, Extensions_Last);
                                 Assert (Extensions_First'Image, Types.Index_Type'Image (45), "Unexpected Extensions'First");
                                 Assert (Extensions_Last'Image, Types.Index_Type'Image (90), "Unexpected Extensions'Last");
                                 Valid := TLS_Handshake.Extensions.Valid_First (Buffer (Extensions_First .. Extensions_Last));
                                 Assert (Valid, "Invalid first extension");
                                 if Valid then
                                    TLS_Handshake.Extensions.Get_First (Buffer (Extensions_First .. Extensions_Last), Offset, Extension_First, Extension_Last);
                                    Assert (Extension_First'Image, Types.Index_Type'Image (45), "Unexpected first Extension'First");
                                    Assert (Extension_Last'Image, Types.Index_Type'Image (50), "Unexpected first Extension'Last");
                                    Valid := TLS_Handshake.Extension.Is_Valid (Buffer (Extension_First .. Extension_Last));
                                    Assert (Valid, "Invalid first extension");
                                    if Valid then
                                       Extension_Tag := TLS_Handshake.Extension.Get_Tag (Buffer (Extension_First .. Extension_Last));
                                       if Extension_Tag.Known then
                                          Assert (Extension_Tag.Enum'Image, TLS_Handshake.Extension_Type_Enum'Image (EXTENSION_SUPPORTED_VERSIONS), "Unexpected first Extension Tag");
                                       else
                                          Assert (False, "Unexpected unknown first Extension Tag");
                                       end if;
                                    end if;
                                    Valid := TLS_Handshake.Extensions.Valid_Next (Buffer (Extensions_First .. Extensions_Last), Offset);
                                    Assert (Valid, "Invalid second extension");
                                    if Valid then
                                       TLS_Handshake.Extensions.Get_Next (Buffer (Extensions_First .. Extensions_Last), Offset, Extension_First, Extension_Last);
                                       Assert (Extension_First'Image, Types.Index_Type'Image (51), "Unexpected second Extension'First");
                                       Assert (Extension_Last'Image, Types.Index_Type'Image (90), "Unexpected second Extension'Last");
                                       Valid := TLS_Handshake.Extension.Is_Valid (Buffer (Extension_First .. Extension_Last));
                                       Assert (Valid, "Invalid second extension");
                                       if Valid then
                                          Extension_Tag := TLS_Handshake.Extension.Get_Tag (Buffer (Extension_First .. Extension_Last));
                                          if Extension_Tag.Known then
                                             Assert (Extension_Tag.Enum'Image, TLS_Handshake.Extension_Type_Enum'Image (EXTENSION_KEY_SHARE), "Unexpected second Extension Tag");
                                          else
                                             Assert (False, "Unexpected unknown second Extension Tag");
                                          end if;
                                       end if;
                                       Valid := TLS_Handshake.Extensions.Valid_Next (Buffer (Extensions_First .. Extensions_Last), Offset);
                                       Assert (not Valid, "Unexpected third extension");
                                    end if;
                                 end if;
                              end if;
                           end if;
                        end if;
                     end if;
                  end if;
                  Valid := TLS_Handshake.Server_Hello.Is_Valid (Buffer (First .. Last));
                  Assert (Valid, "Invalid Server Hello");
               end if;
            end if;
         end if;
      end if;
      Assert (TLS_Handshake.Handshake.Is_Valid (Buffer), "Invalid Handshake");
   end Test_TLS_Handshake_Server_Hello;

   procedure Test_TLS_Handshake_Encrypted_Extensions (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer            : Types.Bytes := Read_File ("tests/tls_handshake_encrypted_extensions.raw");
      Valid             : Boolean;
      Tag               : TLS_Handshake.Handshake_Type;
      Length            : TLS_Handshake.Length_Type;
      First             : Types.Index_Type;
      Last              : Types.Index_Type;
      Extensions_Length : TLS_Handshake.Encrypted_Extensions_Length_Type;
      Extensions_First  : Types.Index_Type;
      Extensions_Last   : Types.Index_Type;
   begin
      TLS_Handshake.Handshake.Label (Buffer);
      Valid := TLS_Handshake.Handshake.Valid_Tag (Buffer);
      Assert (Valid, "Invalid Tag");
      if Valid then
         Tag := TLS_Handshake.Handshake.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Handshake.Handshake_Type'Image (TLS_Handshake.HANDSHAKE_ENCRYPTED_EXTENSIONS), "Unexpected Tag");
         Valid := TLS_Handshake.Handshake.Valid_Length (Buffer);
         Assert (Valid, "Invalid Length");
         if Valid then
            Length := TLS_Handshake.Handshake.Get_Length (Buffer);
            Assert (Length'Image, TLS_Handshake.Length_Type'Image (2), "Unexpected Length");
            Valid := TLS_Handshake.Handshake.Valid_Payload (Buffer);
            Assert (Valid, "Invalid Payload");
            if Valid then
               TLS_Handshake.Handshake.Get_Payload (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (5), "Unexpected Payload'First");
               Assert (Last'Image, Types.Index_Type'Image (6), "Unexpected Payload'Last");
               Valid := TLS_Handshake.Contains.Encrypted_Extensions_Handshake (Buffer);
               Assert (Valid, "Handshake message contains no Encrypted Extensions");
               if Valid then
                  Valid := TLS_Handshake.Encrypted_Extensions.Valid_Length (Buffer (First .. Last));
                  Assert (Valid, "Invalid Extensions Length");
                  if Valid then
                     Extensions_Length := TLS_Handshake.Encrypted_Extensions.Get_Length (Buffer (First .. Last));
                     Assert (Extensions_Length'Image, TLS_Handshake.Encrypted_Extensions_Length_Type'Image (0), "Unexpected Extensions Length");
                     Valid := TLS_Handshake.Encrypted_Extensions.Valid_Extensions (Buffer (First .. Last));
                     Assert (Valid, "Invalid Extensions");
                     if Valid then
                        TLS_Handshake.Encrypted_Extensions.Get_Extensions (Buffer (First .. Last), Extensions_First, Extensions_Last);
                        Assert (Extensions_First'Image, Types.Index_Type'Image (7), "Unexpected Extensions'First");
                        Assert (Extensions_Last'Image, Types.Index_Type'Image (6), "Unexpected Extensions'Last");
                     end if;
                  end if;
                  Valid := TLS_Handshake.Encrypted_Extensions.Is_Valid (Buffer (First .. Last));
                  Assert (Valid, "Invalid Encrypted Extensions");
               end if;
            end if;
         end if;
      end if;
      Assert (TLS_Handshake.Handshake.Is_Valid (Buffer), "Invalid Handshake");
   end Test_TLS_Handshake_Encrypted_Extensions;

   procedure Test_TLS_Handshake_Certificate (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer : Types.Bytes := Read_File ("tests/tls_handshake_certificate.raw");
      Valid  : Boolean;
      Tag    : TLS_Handshake.Handshake_Type;
      Length : TLS_Handshake.Length_Type;
      First  : Types.Index_Type;
      Last   : Types.Index_Type;
   begin
      TLS_Handshake.Handshake.Label (Buffer);
      Valid := TLS_Handshake.Handshake.Valid_Tag (Buffer);
      Assert (Valid, "Invalid Tag");
      if Valid then
         Tag := TLS_Handshake.Handshake.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Handshake.Handshake_Type'Image (TLS_Handshake.HANDSHAKE_CERTIFICATE), "Unexpected Tag");
         Valid := TLS_Handshake.Handshake.Valid_Length (Buffer);
         Assert (Valid, "Invalid Length");
         if Valid then
            Length := TLS_Handshake.Handshake.Get_Length (Buffer);
            Assert (Length'Image, TLS_Handshake.Length_Type'Image (2806), "Unexpected Length");
            Valid := TLS_Handshake.Handshake.Valid_Payload (Buffer);
            Assert (Valid, "Invalid Payload");
            if Valid then
               TLS_Handshake.Handshake.Get_Payload (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (5), "Unexpected Payload'First");
               Assert (Last'Image, Types.Index_Type'Image (2810), "Unexpected Payload'Last");
               Valid := TLS_Handshake.Contains.Certificate_Handshake (Buffer);
               Assert (Valid, "Handshake message contains no Certificate");
               if Valid then
                  Valid := TLS_Handshake.Certificate.Is_Valid (Buffer (First .. Last));
                  Assert (Valid, "Invalid Certificate");
               end if;
            end if;
         end if;
      end if;
      Assert (TLS_Handshake.Handshake.Is_Valid (Buffer), "Invalid Handshake");
   end Test_TLS_Handshake_Certificate;

   procedure Test_TLS_Handshake_Certificate_Verify (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer          : Types.Bytes := Read_File ("tests/tls_handshake_certificate_verify.raw");
      Valid           : Boolean;
      Tag             : TLS_Handshake.Handshake_Type;
      Length          : TLS_Handshake.Length_Type;
      First           : Types.Index_Type;
      Last            : Types.Index_Type;
      Algorithm       : TLS_Handshake.Signature_Scheme;
      Signature_First : Types.Index_Type;
      Signature_Last  : Types.Index_Type;
   begin
      TLS_Handshake.Handshake.Label (Buffer);
      Valid := TLS_Handshake.Handshake.Valid_Tag (Buffer);
      Assert (Valid, "Invalid Tag");
      if Valid then
         Tag := TLS_Handshake.Handshake.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Handshake.Handshake_Type'Image (TLS_Handshake.HANDSHAKE_CERTIFICATE_VERIFY), "Unexpected Tag");
         Valid := TLS_Handshake.Handshake.Valid_Length (Buffer);
         Assert (Valid, "Invalid Length");
         if Valid then
            Length := TLS_Handshake.Handshake.Get_Length (Buffer);
            Assert (Length'Image, TLS_Handshake.Length_Type'Image (75), "Unexpected Length");
            Valid := TLS_Handshake.Handshake.Valid_Payload (Buffer);
            Assert (Valid, "Invalid Payload");
            if Valid then
               TLS_Handshake.Handshake.Get_Payload (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (5), "Unexpected Payload'First");
               Assert (Last'Image, Types.Index_Type'Image (79), "Unexpected Payload'Last");
               Valid := TLS_Handshake.Contains.Certificate_Verify_Handshake (Buffer);
               Assert (Valid, "Handshake message contains no Certificate Verify");
               if Valid then
                  Valid := TLS_Handshake.Certificate_Verify.Valid_Algorithm (Buffer (First .. Last));
                  Assert (Valid, "Invalid Algorithm");
                  if Valid then
                     Algorithm := TLS_Handshake.Certificate_Verify.Get_Algorithm (Buffer (First .. Last));
                     Assert (Algorithm'Image, TLS_Handshake.ECDSA_SECP256R1_SHA256'Image, "Unexpected Algorithm");
                     Valid := TLS_Handshake.Certificate_Verify.Valid_Signature (Buffer (First .. Last));
                     Assert (Valid, "Invalid Signature");
                     if Valid then
                        TLS_Handshake.Certificate_Verify.Get_Signature (Buffer (First .. Last), Signature_First, Signature_Last);
                        Assert (Signature_First'Image, Types.Index_Type'Image (9), "Unexpected Signature'First");
                        Assert (Signature_Last'Image, Types.Index_Type'Image (79), "Unexpected Signature'Last");
                     end if;
                     Valid := TLS_Handshake.Certificate_Verify.Is_Valid (Buffer (First .. Last));
                     Assert (Valid, "Invalid Certificate Verify");
                  end if;
               end if;
            end if;
         end if;
      end if;
   Assert (TLS_Handshake.Handshake.Is_Valid (Buffer), "Invalid Handshake");
   end Test_TLS_Handshake_Certificate_Verify;

   procedure Test_TLS_Handshake_Finished (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer            : Types.Bytes := Read_File ("tests/tls_handshake_finished.raw");
      Valid             : Boolean;
      Tag               : TLS_Handshake.Handshake_Type;
      Length            : TLS_Handshake.Length_Type;
      First             : Types.Index_Type;
      Last              : Types.Index_Type;
      Verify_Data_First : Types.Index_Type;
      Verify_Data_Last  : Types.Index_Type;
   begin
      TLS_Handshake.Handshake.Label (Buffer);
      Valid := TLS_Handshake.Handshake.Valid_Tag (Buffer);
      Assert (Valid, "Invalid Tag");
      if Valid then
         Tag := TLS_Handshake.Handshake.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Handshake.Handshake_Type'Image (TLS_Handshake.HANDSHAKE_FINISHED), "Unexpected Tag");
         Valid := TLS_Handshake.Handshake.Valid_Length (Buffer);
         Assert (Valid, "Invalid Length");
         if Valid then
            Length := TLS_Handshake.Handshake.Get_Length (Buffer);
            Assert (Length'Image, TLS_Handshake.Length_Type'Image (32), "Unexpected Length");
            Valid := TLS_Handshake.Handshake.Valid_Payload (Buffer);
            Assert (Valid, "Invalid Payload");
            if Valid then
               TLS_Handshake.Handshake.Get_Payload (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (5), "Unexpected Payload'First");
               Assert (Last'Image, Types.Index_Type'Image (36), "Unexpected Payload'Last");
               Valid := TLS_Handshake.Contains.Finished_Handshake (Buffer);
               Assert (Valid, "Handshake message contains no Finished");
               if Valid then
                  Valid := TLS_Handshake.Finished.Valid_Verify_Data (Buffer (First .. Last));
                  Assert (Valid, "Invalid Verify_Data");
                  if Valid then
                     TLS_Handshake.Finished.Get_Verify_Data (Buffer (First .. Last), Verify_Data_First, Verify_Data_Last);
                     Assert (Verify_Data_First'Image, Types.Index_Type'Image (5), "Unexpected Verify_Data'First");
                     Assert (Verify_Data_Last'Image, Types.Index_Type'Image (36), "Unexpected Verify_Data'Last");
                  end if;
                  Valid := TLS_Handshake.Finished.Is_Valid (Buffer (First .. Last));
                  Assert (Valid, "Invalid Finished");
               end if;
            end if;
         end if;
      end if;
      Assert (TLS_Handshake.Handshake.Is_Valid (Buffer), "Invalid Handshake");
   end Test_TLS_Handshake_Finished;

   procedure Test_TLS_Handshake_New_Session_Ticket (T : in out Aunit.Test_Cases.Test_Case'Class)
     with SPARK_Mode, Global => null
   is
      pragma Unreferenced (T);
      Buffer              : Types.Bytes := Read_File ("tests/tls_handshake_new_session_ticket.raw");
      Valid               : Boolean;
      Tag                 : TLS_Handshake.Handshake_Type;
      Length              : TLS_Handshake.Length_Type;
      First               : Types.Index_Type;
      Last                : Types.Index_Type;
      Ticket_Lifetime     : TLS_Handshake.Ticket_Lifetime_Type;
      Ticket_Age_Add      : TLS_Handshake.Ticket_Age_Add_Type;
      Ticket_Nonce_Length : TLS_Handshake.Ticket_Nonce_Length_Type;
      Ticket_Nonce_First  : Types.Index_Type;
      Ticket_Nonce_Last   : Types.Index_Type;
      Ticket_Length       : TLS_Handshake.Ticket_Length_Type;
      Ticket_First        : Types.Index_Type;
      Ticket_Last         : Types.Index_Type;
      Extensions_Length   : TLS_Handshake.New_Session_Ticket_Extensions_Length_Type;
      Extensions_First    : Types.Index_Type;
      Extensions_Last     : Types.Index_Type;
   begin
      TLS_Handshake.Handshake.Label (Buffer);
      Valid := TLS_Handshake.Handshake.Valid_Tag (Buffer);
      Assert (Valid, "Invalid Tag");
      if Valid then
         Tag := TLS_Handshake.Handshake.Get_Tag (Buffer);
         Assert (Tag'Image, TLS_Handshake.Handshake_Type'Image (TLS_Handshake.HANDSHAKE_NEW_SESSION_TICKET), "Unexpected Tag");
         Valid := TLS_Handshake.Handshake.Valid_Length (Buffer);
         Assert (Valid, "Invalid Length");
         if Valid then
            Length := TLS_Handshake.Handshake.Get_Length (Buffer);
            Assert (Length'Image, TLS_Handshake.Length_Type'Image (135), "Unexpected Length");
            Valid := TLS_Handshake.Handshake.Valid_Payload (Buffer);
            Assert (Valid, "Invalid Payload");
            if Valid then
               TLS_Handshake.Handshake.Get_Payload (Buffer, First, Last);
               Assert (First'Image, Types.Index_Type'Image (5), "Unexpected Payload'First");
               Assert (Last'Image, Types.Index_Type'Image (139), "Unexpected Payload'Last");
               Valid := TLS_Handshake.Contains.New_Session_Ticket_Handshake (Buffer);
               Assert (Valid, "Handshake message contains no New Session Ticket");
               if Valid then
                  Valid := TLS_Handshake.New_Session_Ticket.Valid_Ticket_Lifetime (Buffer (First .. Last));
                  Assert (Valid, "Invalid Ticket Lifetime");
                  if Valid then
                     Ticket_Lifetime :=  TLS_Handshake.New_Session_Ticket.Get_Ticket_Lifetime (Buffer (First .. Last));
                     Assert (Ticket_Lifetime'Image, TLS_Handshake.Ticket_Lifetime_Type'Image (172800), "Unexpected Ticket Lifetime");
                     Valid := TLS_Handshake.New_Session_Ticket.Valid_Ticket_Age_Add (Buffer (First .. Last));
                     Assert (Valid, "Invalid Ticket Age Add");
                     if Valid then
                        Ticket_Age_Add :=  TLS_Handshake.New_Session_Ticket.Get_Ticket_Age_Add (Buffer (First .. Last));
                        Assert (Ticket_Age_Add'Image, TLS_Handshake.Ticket_Age_Add_Type'Image (787610292), "Unexpected Ticket Age Add");
                        Valid := TLS_Handshake.New_Session_Ticket.Valid_Ticket_Nonce_Length (Buffer (First .. Last));
                        Assert (Valid, "Invalid Ticket Nonce Length");
                        if Valid then
                           Ticket_Nonce_Length :=  TLS_Handshake.New_Session_Ticket.Get_Ticket_Nonce_Length (Buffer (First .. Last));
                           Assert (Ticket_Nonce_Length'Image, TLS_Handshake.Ticket_Nonce_Length_Type'Image (0), "Unexpected Ticket Nonce Length");
                           Valid := TLS_Handshake.New_Session_Ticket.Valid_Ticket_Nonce (Buffer (First .. Last));
                           Assert (Valid, "Invalid Ticket Nonce");
                           if Valid then
                              TLS_Handshake.New_Session_Ticket.Get_Ticket_Nonce (Buffer (First .. Last), Ticket_Nonce_First, Ticket_Nonce_Last);
                              Assert (Ticket_Nonce_First'Image, Types.Index_Type'Image (14), "Unexpected Ticket_Nonce'First");
                              Assert (Ticket_Nonce_Last'Image, Types.Index_Type'Image (13), "Unexpected Ticket_Nonce'Last");
                              Valid := TLS_Handshake.New_Session_Ticket.Valid_Ticket_Length (Buffer (First .. Last));
                              Assert (Valid, "Invalid Ticket Length");
                              if Valid then
                                 Ticket_Length :=  TLS_Handshake.New_Session_Ticket.Get_Ticket_Length (Buffer (First .. Last));
                                 Assert (Ticket_Length'Image, TLS_Handshake.Ticket_Length_Type'Image (122), "Unexpected Ticket Length");
                                 Valid := TLS_Handshake.New_Session_Ticket.Valid_Ticket (Buffer (First .. Last));
                                 Assert (Valid, "Invalid Ticket");
                                 if Valid then
                                    TLS_Handshake.New_Session_Ticket.Get_Ticket (Buffer (First .. Last), Ticket_First, Ticket_Last);
                                    Assert (Ticket_First'Image, Types.Index_Type'Image (16), "Unexpected Ticket'First");
                                    Assert (Ticket_Last'Image, Types.Index_Type'Image (137), "Unexpected Ticket'Last");
                                    Valid := TLS_Handshake.New_Session_Ticket.Valid_Extensions_Length (Buffer (First .. Last));
                                    Assert (Valid, "Invalid Extensions Length");
                                    if Valid then
                                       Extensions_Length :=  TLS_Handshake.New_Session_Ticket.Get_Extensions_Length (Buffer (First .. Last));
                                       Assert (Extensions_Length'Image, TLS_Handshake.New_Session_Ticket_Extensions_Length_Type'Image (0), "Unexpected Extensions Length");
                                       Valid := TLS_Handshake.New_Session_Ticket.Valid_Extensions (Buffer (First .. Last));
                                       Assert (Valid, "Invalid Extensions");
                                       if Valid then
                                          TLS_Handshake.New_Session_Ticket.Get_Extensions (Buffer (First .. Last), Extensions_First, Extensions_Last);
                                          Assert (Extensions_First'Image, Types.Index_Type'Image (140), "Unexpected Extensions'First");
                                          Assert (Extensions_Last'Image, Types.Index_Type'Image (139), "Unexpected Extensions'Last");
                                       end if;
                                    end if;
                                 end if;
                              end if;
                           end if;
                        end if;
                     end if;
                  end if;
                  Valid := TLS_Handshake.New_Session_Ticket.Is_Valid (Buffer (First .. Last));
                  Assert (Valid, "Invalid New Session Ticket");
               end if;
            end if;
         end if;
      end if;
      Assert (TLS_Handshake.Handshake.Is_Valid (Buffer), "Invalid Handshake");
   end Test_TLS_Handshake_New_Session_Ticket;

   procedure Register_Tests (T : in out Test) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_TLS_Handshake_Client_Hello'Access, "TLS Handshake Client Hello");
      Register_Routine (T, Test_TLS_Handshake_Server_Hello'Access, "TLS Handshake Server Hello");
      Register_Routine (T, Test_TLS_Handshake_Encrypted_Extensions'Access, "TLS Handshake Encrypted Extensions");
      Register_Routine (T, Test_TLS_Handshake_Certificate'Access, "TLS Handshake Certificate");
      Register_Routine (T, Test_TLS_Handshake_Certificate_Verify'Access, "TLS Handshake Certificate Verify");
      Register_Routine (T, Test_TLS_Handshake_Finished'Access, "TLS Handshake Finished");
      Register_Routine (T, Test_TLS_Handshake_New_Session_Ticket'Access, "TLS Handshake New Session Ticket");
   end Register_Tests;

end TLS_Handshake.Tests;
