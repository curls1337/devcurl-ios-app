package com.devcurl.studio.mobile;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {

    public static class MessageItem {
        public String sender;
        public String content;
        public boolean isUser;

        public MessageItem(String sender, String content, boolean isUser) {
            this.sender = sender;
            this.content = content;
            this.isUser = isUser;
        }
    }

    private final List<MessageItem> messageList = new ArrayList<>();
    private ChatRecyclerAdapter adapter;
    private RecyclerView recyclerView;
    private EditText inputMessage;
    private Button btnSend;
    private Toolbar toolbar;

    private String activeAgent = "ubuntu-admin";
    private String activeAgentName = "Ubuntu Admin";
    private String activeAgentIcon = "🐧";

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final String SERVER_API = "http://192.168.18.200:8080/api/projects/discovery/chat";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        updateToolbar();

        toolbar.setOnClickListener(v -> showAgentDialog());

        recyclerView = findViewById(R.id.recyclerView);
        inputMessage = findViewById(R.id.inputMessage);
        btnSend = findViewById(R.id.btnSend);

        adapter = new ChatRecyclerAdapter(messageList);
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        layoutManager.setStackFromEnd(true);
        recyclerView.setLayoutManager(layoutManager);
        recyclerView.setAdapter(adapter);

        // Initial Native Message
        messageList.add(new MessageItem(activeAgentIcon + " " + activeAgentName,
                "Halo Pak cURLdev! Aplikasi Android ini berjalan 100% native Java & RecyclerView tanpa WebView. Ada instruksi atau ide yang ingin didiskusikan?", false));
        adapter.notifyItemInserted(0);

        btnSend.setOnClickListener(v -> sendMessage());
    }

    private void updateToolbar() {
        if (toolbar != null) {
            toolbar.setTitle("DevCurl AI");
            toolbar.setSubtitle(activeAgentIcon + " " + activeAgentName);
        }
    }

    private void showAgentDialog() {
        String[] agents = {
                "🐧 Ubuntu Admin (Root Controller)",
                "📦 Product Manager (PRD & Backlog)",
                "🎨 UI/UX Designer (Liquid Glass)",
                "💻 Frontend Developer (Android & Swift)",
                "⚙️ Backend Developer (APIs & Database)",
                "🏗️ Solution Architect (System Arch)",
                "🛡️ QA & Security (Testing)",
                "👥 Semua Agen (Roundtable)"
        };
        String[] keys = {
                "ubuntu-admin", "product-manager", "ui-ux-designer",
                "frontend-developer", "backend-developer", "solution-architect",
                "qa-security", "all"
        };
        String[] icons = {"🐧", "📦", "🎨", "💻", "⚙️", "🏗️", "🛡️", "👥"};
        String[] names = {
                "Ubuntu Admin", "Product Manager", "UI/UX Designer",
                "Frontend Dev", "Backend Dev", "Architect",
                "QA & Security", "Semua Agen"
        };

        new AlertDialog.Builder(this)
                .setTitle("Pilih Agen Spesialis")
                .setItems(agents, (dialog, which) -> {
                    activeAgent = keys[which];
                    activeAgentIcon = icons[which];
                    activeAgentName = names[which];
                    updateToolbar();

                    messageList.add(new MessageItem("👥 Sistem", "Beralih ke " + activeAgentIcon + " " + activeAgentName, false));
                    adapter.notifyItemInserted(messageList.size() - 1);
                    recyclerView.smoothScrollToPosition(messageList.size() - 1);
                })
                .show();
    }

    private void sendMessage() {
        String text = inputMessage.getText().toString().trim();
        if (text.isEmpty()) return;

        inputMessage.setText("");
        messageList.add(new MessageItem("Pak cURLdev", text, true));
        adapter.notifyItemInserted(messageList.size() - 1);
        recyclerView.smoothScrollToPosition(messageList.size() - 1);

        btnSend.setEnabled(false);

        executor.execute(() -> {
            try {
                URL url = new URL(SERVER_API);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("POST");
                conn.setRequestProperty("Content-Type", "application/json");
                conn.setConnectTimeout(25000);
                conn.setReadTimeout(25000);
                conn.setDoOutput(true);

                JSONObject payload = new JSONObject();
                JSONArray messagesArray = new JSONArray();

                for (MessageItem msg : messageList) {
                    JSONObject obj = new JSONObject();
                    obj.put("role", msg.isUser ? "user" : "assistant");
                    obj.put("content", msg.content);
                    messagesArray.put(obj);
                }

                payload.put("messages", messagesArray);
                payload.put("active_agent", activeAgent);
                payload.put("speaker", "Pak cURLdev");

                try (OutputStream os = conn.getOutputStream()) {
                    byte[] input = payload.toString().getBytes(StandardCharsets.UTF_8);
                    os.write(input, 0, input.length);
                }

                int code = conn.getResponseCode();
                if (code == 200) {
                    BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8));
                    StringBuilder response = new StringBuilder();
                    String line;
                    while ((line = br.readLine()) != null) response.append(line);

                    JSONObject jsonResponse = new JSONObject(response.toString());
                    String reply = jsonResponse.optString("reply", "Perintah diterima.");

                    mainHandler.post(() -> {
                        messageList.add(new MessageItem(activeAgentIcon + " " + activeAgentName, reply, false));
                        adapter.notifyItemInserted(messageList.size() - 1);
                        recyclerView.smoothScrollToPosition(messageList.size() - 1);
                        btnSend.setEnabled(true);
                    });
                } else {
                    mainHandler.post(() -> {
                        Toast.makeText(MainActivity.this, "Server error: " + code, Toast.LENGTH_SHORT).show();
                        btnSend.setEnabled(true);
                    });
                }
            } catch (Exception e) {
                mainHandler.post(() -> {
                    Toast.makeText(MainActivity.this, "Gagal konek server: " + e.getMessage(), Toast.LENGTH_LONG).show();
                    btnSend.setEnabled(true);
                });
            }
        });
    }

    private static class ChatRecyclerAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
        private final List<MessageItem> items;

        public ChatRecyclerAdapter(List<MessageItem> items) {
            this.items = items;
        }

        @Override
        public int getItemViewType(int position) {
            return items.get(position).isUser ? 1 : 0;
        }

        @NonNull
        @Override
        public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            if (viewType == 1) {
                View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_message_user, parent, false);
                return new UserViewHolder(view);
            } else {
                View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_message_agent, parent, false);
                return new AgentViewHolder(view);
            }
        }

        @Override
        public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
            MessageItem item = items.get(position);
            if (holder instanceof UserViewHolder) {
                ((UserViewHolder) holder).txtContent.setText(item.content);
            } else if (holder instanceof AgentViewHolder) {
                ((AgentViewHolder) holder).txtSender.setText(item.sender);
                ((AgentViewHolder) holder).txtContent.setText(item.content);
            }
        }

        @Override
        public int getItemCount() {
            return items.size();
        }

        static class UserViewHolder extends RecyclerView.ViewHolder {
            TextView txtContent;
            UserViewHolder(View itemView) {
                super(itemView);
                txtContent = itemView.findViewById(R.id.txtContent);
            }
        }

        static class AgentViewHolder extends RecyclerView.ViewHolder {
            TextView txtSender, txtContent;
            AgentViewHolder(View itemView) {
                super(itemView);
                txtSender = itemView.findViewById(R.id.txtSender);
                txtContent = itemView.findViewById(R.id.txtContent);
            }
        }
    }
}
