import java.io.*;
import java.nio.file.*;
import java.sql.*;

public class FileProcessor {

    // ── Konfiguration ─────────────────────────────────────────
    private static final String DIRECTORY   = "C:\\dein\\verzeichnis";
    private static final String DB_URL      = 
        "jdbc:sqlserver://dein-server:1433;"
        + "databaseName=deineDatenbank;"
        + "integratedSecurity=true;"          // Windows Authentication
        + "trustServerCertificate=true;";
    private static final String SP_NAME     = "dbo.usp_UpdateMyRules";

    // ── Main ──────────────────────────────────────────────────
    public static void main(String[] args) {
        FileProcessor processor = new FileProcessor();
        processor.processDirectory();
    }

    // ── Verzeichnis verarbeiten ───────────────────────────────
    public void processDirectory() {

        File dir = new File(DIRECTORY);
        File[] files = dir.listFiles(
            (d, name) -> name.endsWith(".txt")   // nur .txt-Dateien
        );

        if (files == null || files.length == 0) {
            System.out.println("Keine Dateien gefunden in: " + DIRECTORY);
            return;
        }

        System.out.println("Gefundene Dateien: " + files.length);

        try (Connection conn = DriverManager.getConnection(DB_URL)) {
            System.out.println("DB-Verbindung erfolgreich.");

            for (File file : files) {
                processFile(conn, file);
            }

        } catch (SQLException e) {
            System.err.println("DB-Verbindungsfehler: " + e.getMessage());
        }
    }

    // ── Einzelne Datei verarbeiten ────────────────────────────
    private void processFile(Connection conn, File file) {

        String fileName = file.getName();

        // ── PK aus Dateiname extrahieren ──────────────────────
        Integer myID = extractID(fileName);
        if (myID == null) {
            System.err.println("Übersprungen (kein gültiger PK): " + fileName);
            return;
        }

        // ── Dateiinhalt lesen ─────────────────────────────────
        String myRules = readFileContent(file);
        if (myRules == null) {
            System.err.println("Fehler beim Lesen: " + fileName);
            return;
        }

        // ── Stored Procedure aufrufen ─────────────────────────
        boolean success = callStoredProcedure(conn, myID, myRules);

        if (success) {
            System.out.println("OK: " + fileName + " → myID=" + myID);
        } else {
            System.err.println("Fehler bei SP-Aufruf: " + fileName);
        }
    }

    // ── PK aus Dateiname extrahieren ──────────────────────────
    private Integer extractID(String fileName) {
        try {
            // Alles vor dem ersten Unterstrich
            String idPart = fileName.split("_")[0];
            return Integer.parseInt(idPart);
        } catch (NumberFormatException | ArrayIndexOutOfBoundsException e) {
            return null;   // kein gültiger numerischer PK
        }
    }

    // ── Dateiinhalt komplett lesen ────────────────────────────
    private String readFileContent(File file) {
        try {
            return new String(Files.readAllBytes(file.toPath()));
        } catch (IOException e) {
            System.err.println("Lesefehler: " + e.getMessage());
            return null;
        }
    }

    // ── Stored Procedure aufrufen ─────────────────────────────
    private boolean callStoredProcedure(Connection conn, int myID, String myRules) {
        String sql = "{ CALL " + SP_NAME + "(?, ?) }";

        try (CallableStatement cs = conn.prepareCall(sql)) {
            cs.setInt(1, myID);        // Parameter 1: PK
            cs.setString(2, myRules);  // Parameter 2: Dateiinhalt
            cs.execute();
            return true;

        } catch (SQLException e) {
            System.err.println("SP-Fehler (myID=" + myID + "): " + e.getMessage());
            return false;
        }
    }
}
